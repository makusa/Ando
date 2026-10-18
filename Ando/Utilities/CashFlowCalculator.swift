//
//  CashFlowCalculator.swift
//  Ando
//
//  Projects the end-of-month treasury position by combining what has already
//  happened this month (realized) with what is still expected before month-end
//  (upcoming recurring occurrences + scheduled transactions). No averaging:
//  only real amounts and real remaining occurrences, so no double-counting.
//

import Foundation

// MARK: - Summary

struct CashFlowSummary {
    let displayCurrency: String
    let hasConversion: Bool

    /// Already realized since the 1st of the month (already reflected in balances).
    let realizedIncome: Decimal
    let realizedExpense: Decimal

    /// Still expected before month-end (recurring not yet generated + scheduled).
    let upcomingIncome: Decimal
    let upcomingExpense: Decimal

    /// Current treasury balance (checking + savings + cash), converted.
    let currentTreasury: Decimal
    /// currentTreasury + upcomingIncome − upcomingExpense.
    let projectedEndBalance: Decimal

    /// Native per-currency breakdown (shown when a conversion occurs).
    let byCurrency: [CashFlowCurrencyRow]

    /// Nombre de montants exclus des totaux faute de taux de change.
    /// Les totaux ci-dessus ne les comptent pas : ils sont donc partiels.
    let missingConversions: Int

    /// `true` quand au moins un montant manque aux totaux.
    var isPartial: Bool { missingConversions > 0 }

    var realizedNet: Decimal { realizedIncome - realizedExpense }
    var upcomingNet:  Decimal { upcomingIncome - upcomingExpense }
}

struct CashFlowCurrencyRow: Identifiable {
    let id = UUID()
    let currency: String
    let realizedIncome:  Decimal
    let realizedExpense: Decimal
    let upcomingIncome:  Decimal
    let upcomingExpense: Decimal
    let treasury:        Decimal

    var hasUpcoming: Bool {
        (upcomingIncome as NSDecimalNumber).doubleValue != 0 ||
        (upcomingExpense as NSDecimalNumber).doubleValue != 0
    }
}

// MARK: - Calculator

enum CashFlowCalculator {

    /// Build an end-of-month projection for the given display currency.
    ///
    /// `convert` maps (montant, depuis, vers) → montant converti, ou **nil**
    /// quand le taux est inconnu. Passer `rates.convert`. Un nil exclut le
    /// montant des totaux et incrémente `missingConversions` ; il n'est
    /// jamais additionné tel quel.
    static func summary(
        displayCurrency: String,
        monthTransactions: [Transaction],
        recurring: [RecurringTransaction],
        treasuryAccounts: [Account],
        monthStart: Date,
        monthEnd: Date,            // exclusive: start of next month
        convert: (Decimal, String, String) -> Decimal?
    ) -> CashFlowSummary {

        var realIncome:  [String: Decimal] = [:]
        var realExpense: [String: Decimal] = [:]
        var upIncome:    [String: Decimal] = [:]
        var upExpense:   [String: Decimal] = [:]
        var treasury:    [String: Decimal] = [:]

        // ── Realized: month transactions counting toward balance, no transfers ──
        for tx in monthTransactions
        where tx.transferPairId == nil && tx.status.countsTowardBalance {
            let cur = tx.account?.currency ?? displayCurrency
            if tx.type == .income { realIncome[cur, default: 0]  += tx.amount }
            else                  { realExpense[cur, default: 0] += tx.amount }
        }

        // ── Upcoming (entered): scheduled transactions dated within this month ──
        for tx in monthTransactions
        where tx.transferPairId == nil && tx.status == .scheduled && tx.date < monthEnd {
            let cur = tx.account?.currency ?? displayCurrency
            if tx.type == .income { upIncome[cur, default: 0]  += tx.amount }
            else                  { upExpense[cur, default: 0] += tx.amount }
        }

        // ── Upcoming (recurring): occurrences not yet generated, before month-end.
        // Excludes transfers (no net flow) and savings-project contributions
        // (internal moves). Loan/credit-line payments ARE included via their rules.
        for rule in recurring
        where rule.isActive && !rule.isTransfer && rule.savingsProject == nil {
            let occ = remainingOccurrences(rule: rule, monthStart: monthStart, monthEnd: monthEnd)
            guard occ > 0 else { continue }
            let cur   = rule.account?.currency ?? displayCurrency
            let total = rule.amount * Decimal(occ)
            if rule.type == .income { upIncome[cur, default: 0]  += total }
            else                    { upExpense[cur, default: 0] += total }
        }

        // ── Current treasury balance (checking + savings + cash) ──
        for acc in treasuryAccounts {
            treasury[acc.currency, default: 0] += acc.balance
        }

        // ── Per-currency rows + conversion ──
        let currencies = Set(realIncome.keys).union(realExpense.keys)
            .union(upIncome.keys).union(upExpense.keys).union(treasury.keys)

        let rows = currencies.sorted().map { cur in
            CashFlowCurrencyRow(
                currency: cur,
                realizedIncome:  realIncome[cur]  ?? 0,
                realizedExpense: realExpense[cur] ?? 0,
                upcomingIncome:  upIncome[cur]    ?? 0,
                upcomingExpense: upExpense[cur]   ?? 0,
                treasury:        treasury[cur]    ?? 0
            )
        }

        // Un montant dont la devise n'a pas de taux est EXCLU du total et
        // compté à part. L'additionner brut donnerait un flux de trésorerie
        // faux sans aucun signal.
        var manquants = 0
        func total(_ dict: [String: Decimal]) -> Decimal {
            var somme = MultiCurrencyTotal()
            for (devise, montant) in dict {
                somme.add(convert(montant, devise, displayCurrency))
            }
            manquants += somme.missing
            return somme.value
        }
        let cRealInc  = total(realIncome)
        let cRealExp  = total(realExpense)
        let cUpInc    = total(upIncome)
        let cUpExp    = total(upExpense)
        let cTreasury = total(treasury)

        return CashFlowSummary(
            displayCurrency: displayCurrency,
            hasConversion: currencies.contains { $0 != displayCurrency },
            realizedIncome: cRealInc,
            realizedExpense: cRealExp,
            upcomingIncome: cUpInc,
            upcomingExpense: cUpExp,
            currentTreasury: cTreasury,
            projectedEndBalance: cTreasury + cUpInc - cUpExp,
            byCurrency: rows,
            missingConversions: manquants
        )
    }

    /// Number of occurrences of `rule` that fall within the current month and are
    /// not yet generated. Counts from `nextDueDate` (the next ungenerated occurrence),
    /// skipping any occurrence dated before the month, bounded by `endDate`.
    static func remainingOccurrences(rule: RecurringTransaction,
                                     monthStart: Date,
                                     monthEnd: Date) -> Int {
        var d = rule.nextDueDate
        var guardCount = 0
        // Skip occurrences dated before the current month (overdue from prior months).
        while d < monthStart && guardCount < 2000 {
            d = rule.frequency.nextDate(after: d)
            guardCount += 1
        }
        var count = 0
        while d < monthEnd && guardCount < 2000 {
            if let end = rule.endDate, d > end { break }
            count += 1
            d = rule.frequency.nextDate(after: d)
            guardCount += 1
        }
        return count
    }
}
