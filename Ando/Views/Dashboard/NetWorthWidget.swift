//
//  NetWorthWidget.swift
//  Ando
//
//  Displays: total assets (positive account balances) − total liabilities
//  (negative account balances: credit cards/overdrafts, + loans + credit lines)
//  = net worth, with a visual asset/liability breakdown.
//

import SwiftUI
import SwiftData
import Charts

struct NetWorthWidget: View {
    @Environment(LanguageManager.self) private var lang
    @Environment(ExchangeRateManager.self) private var rates

    // Data passed from parent (already queried)
    let accounts: [Account]
    let loans: [Loan]
    let creditLines: [CreditLine]

    private let display: String

    init(accounts: [Account],
         loans: [Loan],
         creditLines: [CreditLine]) {
        self.accounts    = accounts
        self.loans       = loans
        self.creditLines = creditLines
        self.display     = ExchangeRateManager.shared.displayCurrency
    }

    // MARK: Computed

    // Chaque total ne compte QUE ce qui a pu être converti et retient combien
    // de postes manquent. Additionner un solde non converti donnerait un
    // patrimoine net faux sans aucun signal — voir MultiCurrencyTotal.

    /// Actifs = comptes à solde positif (chèque, épargne, placement…),
    /// chacun converti depuis sa propre devise.
    private var assets: MultiCurrencyTotal {
        var total = MultiCurrencyTotal()
        for acc in accounts where acc.balance > 0 {
            total.add(ExchangeRateManager.shared.convert(acc.balance, from: acc.currency, to: display))
        }
        return total
    }

    /// Dette portée par les comptes eux-mêmes : cartes de crédit et découverts
    /// (soldes négatifs), comptée en valeur absolue.
    private var accountDebt: MultiCurrencyTotal {
        var total = MultiCurrencyTotal()
        for acc in accounts where acc.balance < 0 {
            total.add(ExchangeRateManager.shared.convert(-acc.balance, from: acc.currency, to: display))
        }
        return total
    }

    private var loanDebt: MultiCurrencyTotal {
        var total = MultiCurrencyTotal()
        for loan in loans {
            let bal = Decimal(loan.calculator.currentBalance)
            total.add(ExchangeRateManager.shared.convert(bal, from: loan.currency, to: display))
        }
        return total
    }

    private var creditLineDebt: MultiCurrencyTotal {
        var total = MultiCurrencyTotal()
        for cl in creditLines {
            total.add(ExchangeRateManager.shared.convert(cl.currentBalance, from: cl.currency, to: display))
        }
        return total
    }

    private var totalAssets: Decimal      { assets.value }
    private var totalAccountDebt: Decimal { accountDebt.value }
    private var totalLoanDebt: Decimal    { loanDebt.value }
    private var totalCLDebt: Decimal      { creditLineDebt.value }
    private var totalLiabilities: Decimal { totalAccountDebt + totalLoanDebt + totalCLDebt }
    private var netWorth: Decimal         { totalAssets - totalLiabilities }

    /// Nombre de postes absents du calcul, toutes catégories confondues.
    private var missingCount: Int {
        assets.missing + accountDebt.missing + loanDebt.missing + creditLineDebt.missing
    }

    /// `true` dès qu'un poste manque : le chiffre affiché est alors partiel
    /// et doit le dire.
    private var isPartial: Bool { missingCount > 0 }

    private var debtRatio: Double {
        guard totalAssets > 0 else { return 0 }
        return (totalLiabilities as NSDecimalNumber).doubleValue
             / (totalAssets       as NSDecimalNumber).doubleValue
    }

    private var ratioColor: Color {
        switch debtRatio {
        case ..<0.30: return .green
        case ..<0.60: return .orange
        default:      return .red
        }
    }

    // MARK: View

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Header
            HStack {
                Text(lang["widget.netWorth.title"])
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(.secondary)
                Spacer()
                Text(lang["widget.netWorth.subtitle"])
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal)

            // Card
            VStack(alignment: .leading, spacing: 14) {

                // Net worth big number
                HStack(alignment: .firstTextBaseline, spacing: 8) {
                    Text((isPartial ? "≈ " : "") + netWorth.formatted(asCurrency: display))
                        .font(.title.weight(.bold))
                        .foregroundStyle(netWorth >= 0 ? Color.primary : Color.red)
                        .minimumScaleFactor(0.6)
                        .lineLimit(1)
                    Spacer()
                    // Debt ratio badge
                    if totalLiabilities > 0 && totalAssets > 0 {
                        VStack(alignment: .trailing, spacing: 1) {
                            Text(String(format: "%.0f%%", debtRatio * 100))
                                .font(.callout.weight(.bold))
                                .foregroundStyle(ratioColor)
                            Text(lang["widget.netWorth.debtRatio"])
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                    }
                }

                // Le total ne couvre pas tout : le dire plutôt que de laisser
                // croire à un chiffre complet. Les postes dont la devise n'a
                // pas pu être convertie sont exclus, pas additionnés bruts.
                if isPartial {
                    Label(missingCount == 1
                            ? lang["fx.partial.one"]
                            : lang.f("fx.partial.many", missingCount),
                          systemImage: "exclamationmark.triangle.fill")
                        .font(.caption)
                        .foregroundStyle(.orange)
                }

                // Stacked bar: assets vs liabilities
                if totalAssets > 0 || totalLiabilities > 0 {
                    GeometryReader { geo in
                        let total = (totalAssets + totalLiabilities as NSDecimalNumber).doubleValue
                        let assetW = total > 0
                            ? geo.size.width * CGFloat((totalAssets as NSDecimalNumber).doubleValue / total)
                            : 0
                        HStack(spacing: 2) {
                            RoundedRectangle(cornerRadius: 5, style: .continuous)
                                .fill(Color.green)
                                .frame(width: max(assetW, 4), height: 10)
                            RoundedRectangle(cornerRadius: 5, style: .continuous)
                                .fill(Color.red.opacity(0.75))
                                .frame(width: max(geo.size.width - assetW - 2, 4), height: 10)
                        }
                    }
                    .frame(height: 10)
                }

                Divider()

                // Row breakdown
                Group {
                    netWorthRow(
                        icon: "building.columns.fill",
                        color: .green,
                        label: lang["widget.netWorth.assets"],
                        value: totalAssets,
                        positive: true
                    )
                    if totalAccountDebt > 0 {
                        netWorthRow(
                            icon: "creditcard.fill",
                            color: .red,
                            label: lang["widget.netWorth.cards"],
                            value: totalAccountDebt,
                            positive: false
                        )
                    }
                    if totalLoanDebt > 0 {
                        netWorthRow(
                            icon: "banknote.fill",
                            color: .red,
                            label: lang["loan.title"],
                            value: totalLoanDebt,
                            positive: false
                        )
                    }
                    if totalCLDebt > 0 {
                        netWorthRow(
                            icon: "creditcard.fill",
                            color: .orange,
                            label: lang["cl.title"],
                            value: totalCLDebt,
                            positive: false
                        )
                    }
                }
            }
            .padding(16)
            .background(Color(.secondarySystemBackground),
                        in: RoundedRectangle(cornerRadius: 12))
            .padding(.horizontal)
        }
    }

    private func netWorthRow(icon: String, color: Color,
                              label: String, value: Decimal,
                              positive: Bool) -> some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .foregroundStyle(color)
                .frame(width: 20)
            Text(label)
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Spacer()
            Text((positive ? "" : "−") + value.formatted(asCurrency: display))
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(positive ? .green : .red)
        }
    }
}
