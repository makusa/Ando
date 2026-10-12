//
//  DataReset.swift
//  FinTrack
//
//  Settings ▸ "Reset all data" must keep its promise: erase every piece of the
//  user's financial data, not just accounts and transactions. Inventory built
//  from the code (October 2026):
//    • all 16 SwiftData models of the schema (FinTrackApp.baseSchema)
//    • scanned receipt images (ReceiptStore) and the institution-logo cache
//    • UserDefaults holding personal data (import mappings, dismissed
//      suggestions with merchant names) and the widget's balances/net worth
//    • bank connections (tokens in the Keychain) and scheduled reminders
//  Kept on purpose: preferences (language, display currency, dashboard layout,
//  tracked currencies, iCloud setting, onboarding tours), app lock / Face ID,
//  and purchases. With iCloud sync on, deletions propagate to other devices.
//
//  If a @Model is added to the schema, add it to `eraseModels` and `report`.
//

import Foundation
import SwiftData
import UIKit
import UserNotifications

@MainActor
enum DataReset {

    /// What is left after a reset, per data type. Every count must be 0
    /// (system categories are recreated and therefore not counted).
    struct Report {
        let remaining: [String: Int]
        var isComplete: Bool { remaining.values.allSatisfy { $0 == 0 } }
        var leftovers: [String] { remaining.filter { $0.value > 0 }.map { "\($0.key): \($0.value)" }.sorted() }
    }

    /// UserDefaults keys that contain personal data rather than preferences.
    static let personalDataKeys = [
        "recurring.dismissedSuggestions",     // merchant names of dismissed suggestions
        "fintrack.import.accountMap_v1",      // imported account ids → user's accounts
        "fintrack.import.csvMappings_v1",     // per-bank CSV column mappings
    ]

    /// Widget data in the App Group: balances, net worth, monthly snapshot.
    static let widgetKeys = [
        FinTrackWidgetData.userDefaultsKey,
        "fintrack.widget.monthStartNetWorth",
        "fintrack.widget.monthStartMonthKey",
    ]

    @discardableResult
    static func eraseAll(context: ModelContext) -> Report {
        eraseModels(in: context)
        try? context.save()

        // Files on the device
        try? FileManager.default.removeItem(at: ReceiptStore.folderURL)
        Task { await BankLogoStore.shared.clear() }

        // Personal data kept outside SwiftData
        personalDataKeys.forEach { UserDefaults.standard.removeObject(forKey: $0) }
        if let group = UserDefaults(suiteName: FinTrackWidgetData.appGroupID) {
            widgetKeys.forEach { group.removeObject(forKey: $0) }
        }
        disconnectAllBankProviders()

        // Reminders mention payees and amounts: remove them whatever the
        // notification permission is now (scheduleAll only does when authorized).
        let center = UNUserNotificationCenter.current()
        center.removeAllPendingNotificationRequests()
        center.removeAllDeliveredNotifications()

        // Back to a fresh install: default categories, empty widget.
        SeedData.seedIfNeeded(context: context)
        WidgetDataWriter.write(context: context)

        return report(context: context)
    }

    // Children before parents keeps the context tidy; no delete rule is .deny.
    private static func eraseModels(in context: ModelContext) {
        deleteAll(AppNotification.self, in: context)
        deleteAll(Transaction.self, in: context)
        deleteAll(RecurringTransaction.self, in: context)
        deleteAll(LoanPrepayment.self, in: context)
        deleteAll(Loan.self, in: context)
        deleteAll(CreditLineEntry.self, in: context)
        deleteAll(CreditLine.self, in: context)
        deleteAll(CreditCardProfile.self, in: context)
        deleteAll(Budget.self, in: context)
        deleteAll(SavingsProject.self, in: context)
        deleteAll(RESPContribution.self, in: context)
        deleteAll(RESPProfile.self, in: context)
        deleteAll(RegisteredRoomPlan.self, in: context)
        deleteAll(RegisteredAccountProfile.self, in: context)
        deleteAll(Account.self, in: context)
        deleteAll(Category.self, in: context)          // system ones are re-seeded
    }

    private static func deleteAll<T: PersistentModel>(_ type: T.Type, in context: ModelContext) {
        for item in (try? context.fetch(FetchDescriptor<T>())) ?? [] {
            context.delete(item)
        }
    }

    #if DEBUG
    /// Self-test (launch with -FTDemoMode -FTResetSelfTest): fills the gaps the
    /// demo data does not cover (a receipt file, personal UserDefaults), erases,
    /// prints the before/after reports and quits with 0 only if nothing remains.
    static func selfTest(context: ModelContext) -> Never {
        // Types the demo household does not contain: one of each, so that every
        // data type of the schema is actually exercised by the test.
        context.insert(AppNotification(kind: .info, title: "test", message: "test"))
        context.insert(CreditCardProfile(creditLimit: 1000))
        context.insert(LoanPrepayment(amount: 100, startDate: .now, isRecurring: false))
        context.insert(RESPProfile(beneficiaryName: "test", birthYear: 2020))
        context.insert(RESPContribution(amount: 50))
        context.insert(RecurringTransaction(title: "test", amount: 10, type: .expense,
                                            frequency: .monthly, startDate: .now))
        context.insert(Category(name: "test", iconSystemName: "tag", colorHex: "#888888",
                                applicability: .expense))
        try? context.save()
        _ = ReceiptStore.save(UIImage(systemName: "doc")!, date: .now, merchant: "test", amount: 1)
        personalDataKeys.forEach { UserDefaults.standard.set("test", forKey: $0) }
        let before = report(context: context)
        let after = eraseAll(context: context)
        print("RESET-SELFTEST before: \(before.remaining.sorted { $0.key < $1.key })")
        print("RESET-SELFTEST after:  \(after.remaining.sorted { $0.key < $1.key })")
        // A type already empty before the reset proves nothing: report it.
        let untested = before.remaining.filter { $0.value == 0 }.map(\.key).sorted()
        print("RESET-SELFTEST not exercised: \(untested.isEmpty ? "none" : untested.joined(separator: ", "))")
        print("RESET-SELFTEST result: \(after.isComplete ? "COMPLETE" : "INCOMPLETE \(after.leftovers)")")
        exit(after.isComplete && untested.isEmpty ? 0 : 1)
    }
    #endif

    /// Counts what remains of each data type.
    static func report(context: ModelContext) -> Report {
        func count<T: PersistentModel>(_ type: T.Type) -> Int {
            (try? context.fetchCount(FetchDescriptor<T>())) ?? -1
        }
        let customCategories = (try? context.fetchCount(
            FetchDescriptor<Category>(predicate: #Predicate { !$0.isSystem }))) ?? -1
        let receiptFiles = (try? FileManager.default
            .contentsOfDirectory(atPath: ReceiptStore.folderURL.path).count) ?? 0
        let personalKeys = personalDataKeys.filter { UserDefaults.standard.object(forKey: $0) != nil }.count

        return Report(remaining: [
            "Account": count(Account.self),
            "Transaction": count(Transaction.self),
            "Category (custom)": customCategories,
            "RecurringTransaction": count(RecurringTransaction.self),
            "Loan": count(Loan.self),
            "LoanPrepayment": count(LoanPrepayment.self),
            "CreditLine": count(CreditLine.self),
            "CreditLineEntry": count(CreditLineEntry.self),
            "SavingsProject": count(SavingsProject.self),
            "Budget": count(Budget.self),
            "CreditCardProfile": count(CreditCardProfile.self),
            "RegisteredAccountProfile": count(RegisteredAccountProfile.self),
            "RegisteredRoomPlan": count(RegisteredRoomPlan.self),
            "RESPProfile": count(RESPProfile.self),
            "RESPContribution": count(RESPContribution.self),
            "AppNotification": count(AppNotification.self),
            "receipt files": receiptFiles,
            "personal UserDefaults keys": personalKeys,
        ])
    }
}
