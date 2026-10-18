//
//  ExchangeRateManager.swift
//  Ando
//
//  Fetches live exchange rates once per session (max every 4 hours).
//  Source: api.exchangerate-api.com/v4/latest/{base} — free, no API key,
//  supports all currencies including XAF and XOF.
//
//  Usage:
//    let manager = ExchangeRateManager.shared
//    await manager.refreshIfNeeded()
//    guard let converted = manager.convert(1000, from: "XAF", to: "CAD")
//    else { /* taux indisponible — ne JAMAIS retomber sur le montant brut */ }
//

import Foundation
import Combine

// MARK: - API response shape

private struct RatesResponse: Decodable {
    let base: String
    let date: String
    let rates: [String: Double]
}

// MARK: - Manager

@Observable
final class ExchangeRateManager {

    static let shared = ExchangeRateManager()

    // MARK: State

    /// Rates relative to the current `baseCurrency` (1 unit of base = X of target)
    private(set) var rates: [String: Decimal] = [:]
    private(set) var baseCurrency: String = "CAD"
    private(set) var lastUpdated: Date? = nil
    private(set) var isLoading: Bool = false
    private(set) var lastError: String? = nil

    // User preferences — stored for fast access during rendering.
    // UserDefaults writes happen only on mutation (not on every getter call).

    /// User-chosen display currency for the global balance.
    var displayCurrency: String = UserDefaults.standard.string(forKey: "displayCurrency") ?? "CAD" {
        didSet {
            guard displayCurrency != oldValue else { return }
            UserDefaults.standard.set(displayCurrency, forKey: "displayCurrency")
        }
    }

    /// Whether converted amounts are shown alongside native currency amounts.
    var showConvertedAmounts: Bool = UserDefaults.standard.bool(forKey: "showConvertedAmounts") {
        didSet {
            guard showConvertedAmounts != oldValue else { return }
            UserDefaults.standard.set(showConvertedAmounts, forKey: "showConvertedAmounts")
        }
    }

    // MARK: Tracked currencies (user-managed; default CAD + USD)

    /// Currencies the user tracks — drives pickers and the rates table. CAD is
    /// pinned (home + FX pivot) and cannot be removed. Rates for ALL currencies
    /// are fetched regardless, so adding one is instant and works offline.
    private(set) var activeCurrencies: [String] = ExchangeRateManager.loadActiveCurrencies()

    static let pinnedCurrency = "CAD"
    private static let activeKey       = "fx.activeCurrencies_v1"
    private static let activeSeededKey = "fx.activeCurrencies.seeded_v1"

    private static func loadActiveCurrencies() -> [String] {
        let stored = UserDefaults.standard.stringArray(forKey: activeKey) ?? []
        return normalizeActive(stored.isEmpty ? ["CAD", "USD"] : stored)
    }

    /// CAD always first & present; de-duplicated; preserves the given order.
    /// Unknown codes are kept (never strand an existing account's currency).
    private static func normalizeActive(_ codes: [String]) -> [String] {
        var seen = Set<String>([pinnedCurrency])
        var out  = [pinnedCurrency]
        for c in codes where !seen.contains(c) {
            out.append(c); seen.insert(c)
        }
        return out
    }

    private let cacheKey      = "exchangeRates_v1"
    private let cacheBaseKey  = "exchangeRatesBase_v1"
    private let cacheDateKey  = "exchangeRatesDate_v1"
    private let cacheMaxAge: TimeInterval = 4 * 60 * 60  // 4 hours

    // MARK: - Init

    private init() {
        loadFromCache()
    }

    // MARK: - Public API

    /// Convertit `amount` de `source` vers `target`.
    ///
    /// Retourne **nil** quand la conversion est impossible : table de taux
    /// vide, devise absente de la table, ou taux nul.
    ///
    /// L'optionnel est délibéré. Jusqu'au 18 octobre 2026, cette fonction
    /// retournait le montant **inchangé** dans ces trois cas : un patrimoine
    /// net mêlant dollars américains et canadiens s'affichait comme si
    /// 1 $ US valait 1 $ CA — environ 40 % d'erreur — sans le moindre
    /// signal, et un virement s'enregistrait au mauvais montant. Ce n'était
    /// pas un oubli : la signature non optionnelle ne permettait rien
    /// d'autre. Le type oblige désormais chaque appelant à trancher.
    func convert(_ amount: Decimal, from source: String, to target: String) -> Decimal? {
        Self.convert(amount, from: source, to: target, rates: rates, base: baseCurrency)
    }

    /// Cœur du calcul, sans état : ni réseau, ni singleton, ni cache.
    /// Isolé pour être testable — c'est l'absence de test sur cette fonction
    /// qui a laissé passer le repli silencieux.
    ///
    /// - Parameters:
    ///   - rates: taux relatifs à `base` (1 unité de `base` = X unités de la clé).
    /// - Returns: le montant converti, ou `nil` si la conversion est impossible.
    static func convert(_ amount: Decimal, from source: String, to target: String,
                        rates: [String: Decimal], base: String) -> Decimal? {
        guard source != target else { return amount }
        guard !rates.isEmpty else { return nil }

        if source == base {
            guard let targetRate = rates[target] else { return nil }
            return amount * targetRate
        } else if target == base {
            guard let sourceRate = rates[source], sourceRate != 0 else { return nil }
            return amount / sourceRate
        } else {
            guard let sourceRate = rates[source], sourceRate != 0,
                  let targetRate = rates[target] else { return nil }
            // source → base → target
            let inBase = amount / sourceRate
            return inBase * targetRate
        }
    }

    /// Montant converti, mis en forme — p. ex. « ≈ 1 234,56 $ CA ».
    /// `nil` si la devise est la même ou si la conversion est impossible.
    func convertedLabel(_ amount: Decimal, from source: String, to target: String) -> String? {
        guard source != target,
              let converted = convert(amount, from: source, to: target)
        else { return nil }
        return "≈ \(converted.formatted(asCurrency: target))"
    }

    /// Refresh if cache is older than `cacheMaxAge` or empty.
    func refreshIfNeeded() async {
        if let last = lastUpdated, Date().timeIntervalSince(last) < cacheMaxAge, !rates.isEmpty {
            return
        }
        await refresh()
    }

    /// Force refresh from network.
    func refresh() async {
        await MainActor.run { isLoading = true; lastError = nil }

        let base = "CAD"
        let urlString = "https://api.exchangerate-api.com/v4/latest/\(base)"
        guard let url = URL(string: urlString) else {
            await MainActor.run { isLoading = false }
            return
        }

        do {
            let (data, response) = try await URLSession.shared.data(from: url)
            guard let http = response as? HTTPURLResponse, http.statusCode == 200 else {
                throw URLError(.badServerResponse)
            }
            let decoded = try JSONDecoder().decode(RatesResponse.self, from: data)

            // Store ALL returned rates (≈160, a few KB) so any tracked currency
            // is convertible instantly — including ones the user adds later, and
            // while offline. The activeCurrencies list governs display only.
            var newRates: [String: Decimal] = [:]
            for (code, rate) in decoded.rates {
                newRates[code] = Decimal(rate)
            }
            newRates[base] = 1  // base = 1

            let now = Date()
            let finalRates = newRates  // Capture immutable copy for @Sendable closure
            await MainActor.run {
                self.rates        = finalRates
                self.baseCurrency = base
                self.lastUpdated  = now
                self.isLoading    = false
            }
            saveToCache(finalRates, base: base, date: now)

        } catch {
            await MainActor.run {
                self.isLoading = false
                self.lastError = error.localizedDescription
            }
        }
    }

    // MARK: - Tracked currencies API

    func isActive(_ code: String) -> Bool { activeCurrencies.contains(code) }

    /// CAD is pinned and cannot be removed.
    func canRemove(_ code: String) -> Bool { code != Self.pinnedCurrency }

    /// Active currencies as CurrencyInfo (CAD first).
    var activeCurrencyInfos: [CurrencyInfo] {
        activeCurrencies.map { Currencies.info(for: $0) }
    }

    func addCurrency(_ code: String) {
        guard !activeCurrencies.contains(code) else { return }
        activeCurrencies = Self.normalizeActive(activeCurrencies + [code])
        persistActive()
    }

    func removeCurrency(_ code: String) {
        guard canRemove(code) else { return }
        activeCurrencies.removeAll { $0 == code }
        if displayCurrency == code { displayCurrency = Self.pinnedCurrency }
        persistActive()
    }

    func setActiveCurrencies(_ codes: [String]) {
        activeCurrencies = Self.normalizeActive(codes)
        if !activeCurrencies.contains(displayCurrency) { displayCurrency = Self.pinnedCurrency }
        persistActive()
    }

    private func persistActive() {
        UserDefaults.standard.set(activeCurrencies, forKey: Self.activeKey)
    }

    /// One-time migration: seed the tracked list from currencies already in use
    /// (so existing accounts/budgets/loans never lose their currency), unioned
    /// with the CAD+USD defaults. Runs once; later launches are no-ops.
    func seedActiveCurrenciesIfNeeded(used: [String]) {
        guard !UserDefaults.standard.bool(forKey: Self.activeSeededKey) else { return }
        activeCurrencies = Self.normalizeActive(["CAD", "USD"] + used.sorted())
        persistActive()
        UserDefaults.standard.set(true, forKey: Self.activeSeededKey)
    }

    // MARK: - Cache

    private func saveToCache(_ rates: [String: Decimal], base: String, date: Date) {
        let dict = rates.mapValues { ($0 as NSDecimalNumber).doubleValue }
        UserDefaults.standard.set(dict,           forKey: cacheKey)
        UserDefaults.standard.set(base,           forKey: cacheBaseKey)
        UserDefaults.standard.set(date,           forKey: cacheDateKey)
    }

    private func loadFromCache() {
        guard let dict     = UserDefaults.standard.dictionary(forKey: cacheKey) as? [String: Double],
              let base     = UserDefaults.standard.string(forKey: cacheBaseKey),
              let date     = UserDefaults.standard.object(forKey: cacheDateKey) as? Date
        else { return }

        rates        = dict.mapValues { Decimal($0) }
        baseCurrency = base
        lastUpdated  = date
    }
}

// MARK: - Somme portant sur plusieurs devises

/// Total d'un ensemble de montants libellés dans des devises différentes.
///
/// `value` ne contient **que** ce qui a pu être converti ; `missing` compte
/// les montants laissés de côté faute de taux. Un total partiel annoncé
/// comme tel est honnête ; un total complet obtenu en additionnant des
/// devises non converties ne l'est pas.
///
/// L'ancien comportement produisait le second : il additionnait les montants
/// bruts, et le tableau de bord affichait même « mis à jour il y a… » —
/// rassurant, et faux.
struct MultiCurrencyTotal {

    private(set) var value: Decimal = 0

    /// Nombre de montants qui n'ont pas pu être convertis.
    private(set) var missing: Int = 0

    /// `true` si au moins un montant manque au total.
    var isPartial: Bool { missing > 0 }

    init() {}

    /// Ajoute le résultat d'une conversion. `nil` incrémente `missing`
    /// au lieu de fausser `value`.
    mutating func add(_ converted: Decimal?) {
        if let converted {
            value += converted
        } else {
            missing += 1
        }
    }
}
