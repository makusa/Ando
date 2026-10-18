//
//  EntitlementManager.swift
//  Ando
//
//  Manages in-app purchases and subscriptions via StoreKit 2.
//
//  Products (configure in App Store Connect):
//    ca.bmsk.ando.pro — Non-consumable, 24,99 $ CAD (achat unique — palier Pro)
//    ca.bmsk.ando.max — Auto-renewable subscription, 6,49 $/mois (palier Max)
//
//  Les prix affichés viennent TOUJOURS de StoreKit, jamais d'ici : ces
//  montants ne sont qu'un repère de lecture. Les cas d'énumération
//  s'appellent encore `epargne` et `placement`, anciens noms des paliers,
//  renommés Pro et Max côté produit en octobre 2026.
//
//  Tier summary:
//    Courant   — gratuit: comptes illimités, max 5 récurrences, max 2 prêts, max 1 marge, max 2 projets, max 3 budgets
//    Épargne   — achat unique: tout illimité + analytiques + export + FX
//    Placement — abonnement: tout Épargne + sync Plaid automatique
//

import StoreKit
import SwiftUI

// MARK: - Product IDs

enum AndoProduct: String, CaseIterable {
    case epargne         = "ca.bmsk.ando.pro"
    case placement = "ca.bmsk.ando.max"

    var displayName: String {
        switch self {
        case .epargne:          return LanguageManager.shared["entitlement.pro.name"]
        case .placement: return LanguageManager.shared["entitlement.plaid.name"]
        }
    }

    var icon: String {
        switch self {
        case .epargne:          return "star.fill"
        case .placement: return "building.columns"
        }
    }
}

// MARK: - Tier

enum AndoTier: Equatable {
    case free
    case epargne           // one-time purchase
    case placement     // abonnement mensuel — Placement (implique Épargne)
}

// MARK: - Limits

enum AndoLimit {
    /// Maximum recurring transactions (active + paused) in the free tier.
    static let freeMaxRecurring = 5
    /// Maximum active loans in the free tier. Archived (paid-off) loans don't count.
    static let freeMaxLoans = 2
    /// Maximum active credit lines in the free tier. Archived lines don't count.
    static let freeMaxCreditLines = 1
    /// Maximum active savings projects in the free tier. Archived projects don't count.
    static let freeMaxSavingsProjects = 2
    /// Maximum active budgets in the free tier. Archived budgets don't count.
    static let freeMaxBudgets = 3
    /// Maximum registered accounts (CELI/CELIAPP/REER) in the free tier.
    static let freeMaxRegisteredAccounts = 2
    /// Maximum user-created (custom) categories in the free tier. System categories don't count.
    static let freeMaxCustomCategories = 3
    /// Maximum tracked currencies in the free tier (CAD is always one of them).
    static let freeMaxCurrencies = 2
}

// MARK: - EntitlementManager

@Observable
final class EntitlementManager {

    static let shared = EntitlementManager()
    private init() {}

    // MARK: State

    private(set) var hasPaidTier:   Bool = false
    private(set) var hasPlacement: Bool = false
    private(set) var isLoading = false
    private(set) var products: [Product] = []
    private(set) var purchaseError: String? = nil

    var tier: AndoTier {
        if hasPlacement { return .placement }
        if hasPaidTier   { return .epargne }
        return .free
    }

    // MARK: - Lifecycle

    func start() async {
        await loadProducts()
        await refreshEntitlements()
        // Transaction listener runs indefinitely — launch as independent Task
        // so it doesn't block start() from returning
        Task { await self.listenForTransactions() }
    }

    // MARK: - Products

    func loadProducts() async {
        do {
            let loaded = try await Product.products(for: AndoProduct.allCases.map { $0.rawValue })
            await MainActor.run {
                self.products = loaded.sorted { $0.price < $1.price }
            }
        } catch {
            AppLogger.entitlements.error("EntitlementManager product load failed: \(error, privacy: .private)")
        }
    }

    func product(for id: AndoProduct) -> Product? {
        products.first { $0.id == id.rawValue }
    }

    // MARK: - Purchase

    @MainActor
    func purchase(_ productId: AndoProduct) async -> Bool {
        guard let product = product(for: productId) else {
            purchaseError = LanguageManager.shared["entitlement.error.unavailable"]
            return false
        }

        isLoading = true
        purchaseError = nil

        do {
            let result = try await product.purchase()
            switch result {
            case .success(let verification):
                let transaction = try checkVerified(verification)
                await updateEntitlements(for: transaction)
                await transaction.finish()
                isLoading = false
                return true

            case .userCancelled:
                isLoading = false
                return false

            case .pending:
                isLoading = false
                return false

            @unknown default:
                isLoading = false
                return false
            }
        } catch {
            purchaseError = error.localizedDescription
            isLoading = false
            return false
        }
    }

    // MARK: - Restore

    @MainActor
    func restore() async {
        isLoading = true
        do {
            try await AppStore.sync()
            await refreshEntitlements()
        } catch {
            purchaseError = error.localizedDescription
        }
        isLoading = false
    }

    // MARK: - Entitlement refresh

    /// UserDefaults key for the persisted developer tier override (DEBUG builds only).
    /// Values: "free" | "epargne" | "placement". Absent = real StoreKit entitlements.
    nonisolated static let devTierOverrideKey = "ando.dev.tierOverride"

    @MainActor
    func refreshEntitlements() async {
        #if DEBUG
        // Developer override — survives app restarts so paid features can be
        // tested across launches. Cleared via clearSimulation().
        if let override = UserDefaults.standard.string(forKey: Self.devTierOverrideKey) {
            switch override {
            case "epargne":   hasPaidTier = true;  hasPlacement = false
            case "placement": hasPaidTier = true;  hasPlacement = true
            default:          hasPaidTier = false; hasPlacement = false
            }
            if !hasPaidTier {
                UserDefaults.standard.set(false, forKey: "ando.cloudSyncEnabled")
            }
            return
        }
        #endif

        var newHasPaidTier   = false
        var newHasPlacement  = false

        for await result in StoreKit.Transaction.currentEntitlements {
            if let transaction = try? checkVerified(result) {
                switch transaction.productID {
                case AndoProduct.epargne.rawValue:
                    newHasPaidTier = true
                case AndoProduct.placement.rawValue:
                    newHasPlacement = true
                    newHasPaidTier  = true  // Placement includes Épargne features
                default:
                    break
                }
            }
        }

        hasPaidTier  = newHasPaidTier
        hasPlacement = newHasPlacement

        // CloudKit sync is a paid feature — if the entitlement lapsed
        // (refund, expired subscription), disable the sync flag so the
        // next launch falls back to the local store.
        if !newHasPaidTier {
            UserDefaults.standard.set(false, forKey: "ando.cloudSyncEnabled")
        }
    }

    // MARK: - Transaction listener

    private func listenForTransactions() async {
        for await result in StoreKit.Transaction.updates {
            if let transaction = try? checkVerified(result) {
                await updateEntitlements(for: transaction)
                await transaction.finish()
            }
        }
    }

    @MainActor
    private func updateEntitlements(for transaction: StoreKit.Transaction) async {
        switch transaction.productID {
        case AndoProduct.epargne.rawValue:
            hasPaidTier = transaction.revocationDate == nil
        case AndoProduct.placement.rawValue:
            hasPlacement = transaction.revocationDate == nil
            if hasPlacement { hasPaidTier = true }  // Placement includes Épargne features
        default:
            break
        }
    }

    // MARK: - Verification

    private func checkVerified<T>(_ result: VerificationResult<T>) throws -> T {
        switch result {
        case .unverified(_, let error):
            throw error
        case .verified(let value):
            return value
        }
    }

    // MARK: - Override (debug / promo)

    #if DEBUG
    @MainActor func simulateEpargne() {
        hasPaidTier = true; hasPlacement = false
        UserDefaults.standard.set("epargne", forKey: Self.devTierOverrideKey)
    }
    @MainActor func simulatePlacement() {
        hasPaidTier = true; hasPlacement = true
        UserDefaults.standard.set("placement", forKey: Self.devTierOverrideKey)
    }
    @MainActor func simulateFree() {
        hasPaidTier = false; hasPlacement = false
        UserDefaults.standard.set("free", forKey: Self.devTierOverrideKey)
        UserDefaults.standard.set(false, forKey: "ando.cloudSyncEnabled")
    }
    /// Removes the developer override and restores real StoreKit entitlements.
    @MainActor func clearSimulation() async {
        UserDefaults.standard.removeObject(forKey: Self.devTierOverrideKey)
        await refreshEntitlements()
    }
    /// True when a persisted developer override is active.
    var isSimulating: Bool {
        UserDefaults.standard.string(forKey: Self.devTierOverrideKey) != nil
    }
    #endif
}
