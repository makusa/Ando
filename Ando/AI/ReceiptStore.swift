//  ReceiptStore.swift — Local receipt image storage (paid AI, Phase 2)
//
//  Receipt images live on-device only (no CloudKit — consistent with local-first,
//  and images are heavy) under Documents/Receipts/, as compressed JPEGs named
//  "date_merchant_amount_xxxx.jpg" for readability. The file name is stored on the
//  Transaction; deleting the transaction should delete the file.
import Foundation
import SwiftData
import UIKit

extension ModelContext {
    /// Deletes a transaction **and** its receipt image.
    ///
    /// Always prefer this to `context.delete(tx)`: the image lives on disk, not
    /// in SwiftData, so deleting the transaction alone leaves the photo behind.
    func deleteTransaction(_ tx: Transaction) {
        if let name = tx.receiptFileName { ReceiptStore.delete(name) }
        delete(tx)
    }
}

enum ReceiptStore {

    /// Documents/Receipts/, created on first access.
    static var folderURL: URL {
        let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let folder = docs.appendingPathComponent("Receipts", isDirectory: true)
        if !FileManager.default.fileExists(atPath: folder.path) {
            try? FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        }
        return folder
    }

    /// Save a receipt image; returns the stored file name (nil on failure).
    static func save(_ image: UIImage, date: Date, merchant: String?, amount: Decimal) -> String? {
        guard let data = image.jpegData(compressionQuality: 0.7) else { return nil }
        let name = makeFileName(date: date, merchant: merchant, amount: amount)
        let url = folderURL.appendingPathComponent(name)
        do { try data.write(to: url, options: .atomic); return name }
        catch { return nil }
    }

    static func load(_ fileName: String) -> UIImage? {
        let url = folderURL.appendingPathComponent(fileName)
        guard let data = try? Data(contentsOf: url) else { return nil }
        return UIImage(data: data)
    }

    static func url(for fileName: String) -> URL {
        folderURL.appendingPathComponent(fileName)
    }

    static func delete(_ fileName: String) {
        try? FileManager.default.removeItem(at: folderURL.appendingPathComponent(fileName))
    }

    // MARK: - Orphan sweep

    /// Deletes receipt images no transaction references any more, and returns how
    /// many were removed.
    ///
    /// Safety net: a transaction can disappear through many paths (swipe delete,
    /// a recurring rule removed, a savings project cleaned up) and, above all,
    /// through a CASCADE when its account is deleted — where no per-transaction
    /// code runs at all. Without this sweep, the photo of a purchase would stay
    /// on the device after the user deleted the transaction.
    ///
    /// Call sites still delete the image immediately (see `ModelContext
    /// .deleteTransaction`); this only catches what they cannot.
    @discardableResult
    static func deleteOrphans(in context: ModelContext) -> Int {
        guard let files = try? FileManager.default.contentsOfDirectory(atPath: folderURL.path),
              !files.isEmpty
        else { return 0 }

        // Fetch only the file names, not whole transactions.
        var descriptor = FetchDescriptor<Transaction>(
            predicate: #Predicate { $0.receiptFileName != nil })
        descriptor.propertiesToFetch = [\.receiptFileName]
        let referenced = Set((try? context.fetch(descriptor))?.compactMap(\.receiptFileName) ?? [])

        var removed = 0
        for file in files where !referenced.contains(file) {
            delete(file)
            removed += 1
        }
        return removed
    }

    // MARK: - Naming

    /// "2026-08-22_Metro_45-67_A1B2C3.jpg" — readable, with a short unique suffix
    /// so two similar receipts never collide.
    private static func makeFileName(date: Date, merchant: String?, amount: Decimal) -> String {
        let df = DateFormatter()
        df.dateFormat = "yyyy-MM-dd"
        df.locale = Locale(identifier: "en_US_POSIX")
        let dateStr = df.string(from: date)
        let merchantStr = sanitize(merchant ?? "recu")
        let amountStr = "\(amount)".replacingOccurrences(of: ".", with: "-")
        let unique = String(UUID().uuidString.prefix(6))
        return "\(dateStr)_\(merchantStr)_\(amountStr)_\(unique).jpg"
    }

    /// Keep alphanumerics, replace the rest with "-", cap length.
    private static func sanitize(_ s: String) -> String {
        var out = ""
        for scalar in s.unicodeScalars {
            out.append(CharacterSet.alphanumerics.contains(scalar) ? Character(scalar) : "-")
        }
        let capped = String(out.prefix(30))
        return capped.trimmingCharacters(in: CharacterSet(charactersIn: "-")).isEmpty
            ? "recu" : capped.trimmingCharacters(in: CharacterSet(charactersIn: "-"))
    }
}

#if DEBUG
extension ReceiptStore {
    /// Self-test (launch with -FTDemoMode -FTReceiptSweepSelfTest): proves the
    /// sweep removes an unreferenced image and, just as importantly, KEEPS one a
    /// transaction still points to. Deleting a live receipt would lose the user's
    /// own photo, so both directions are checked.
    static func sweepSelfTest(context: ModelContext) -> Never {
        let image = UIImage(systemName: "doc")!

        // Referenced: attached to a real transaction in the store.
        let account = Account(name: "Test", institution: "Test", type: .checking, currency: "CAD")
        context.insert(account)
        let tx = Transaction(amount: 1, type: .expense, date: .now, account: account)
        tx.receiptFileName = save(image, date: .now, merchant: "garder", amount: 1)
        context.insert(tx)
        try? context.save()

        // Orphan: on disk, referenced by nothing.
        let orphan = save(image, date: .now, merchant: "orphelin", amount: 2)

        let before = (try? FileManager.default.contentsOfDirectory(atPath: folderURL.path))?.count ?? 0
        let removed = deleteOrphans(in: context)
        let after = Set((try? FileManager.default.contentsOfDirectory(atPath: folderURL.path)) ?? [])

        let keptLive = tx.receiptFileName.map(after.contains) ?? false
        let orphanGone = orphan.map { !after.contains($0) } ?? false
        let ok = keptLive && orphanGone && removed == 1

        let rapport = """
        SWEEP-SELFTEST files before: \(before), removed: \(removed), after: \(after.count)
        SWEEP-SELFTEST referenced receipt kept: \(keptLive)
        SWEEP-SELFTEST orphan removed: \(orphanGone)
        SWEEP-SELFTEST result: \(ok ? "PASS" : "FAIL")
        """
        print(rapport)
        // Également sur disque : la sortie console d'un lancement par simctl
        // n'est pas toujours capturable, le fichier l'est toujours.
        let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        try? rapport.write(to: docs.appendingPathComponent("sweep-selftest.txt"),
                           atomically: true, encoding: .utf8)
        exit(ok ? 0 : 1)
    }
}
#endif
