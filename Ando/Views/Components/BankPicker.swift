//
//  BankPicker.swift
//  Ando
//
//  Three composable pieces:
//    • BankLogoView           — institution logo, with a monogram fallback
//    • InstitutionPickerField — drop-in replacement for a plain institution TextField
//    • BankPickerSheet        — searchable full-screen bank browser
//
//  Logos come from Ando's own server (ando.bmsk.ca/api/logo/<domain>),
//  which fetches them from Logo.dev. The app never contacts Logo.dev directly,
//  so the logo provider never sees the user's device or IP address. Logos are
//  kept on the device; the monogram shows while loading, offline, or when an
//  institution has no logo. Attribution to Logo.dev is shown in Settings ▸ About.
//

import SwiftUI

// MARK: - Logo store (device cache + Ando server)

/// Loads institution logos once, keeps them on the device, and deduplicates
/// concurrent requests for the same institution.
actor BankLogoStore {
    static let shared = BankLogoStore()

    private static let baseURL = URL(string: "https://ando.bmsk.ca/api/logo/")!
    private static let logoLifetime: TimeInterval = 30 * 24 * 3600     // refresh monthly
    private static let missingLifetime: TimeInterval = 7 * 24 * 3600  // retry weekly

    /// No cookies, no shared URL cache: the request carries nothing but the domain.
    private static let session: URLSession = {
        let configuration = URLSessionConfiguration.ephemeral
        configuration.httpCookieStorage = nil
        configuration.urlCache = nil
        return URLSession(configuration: configuration)
    }()

    private let memory = NSCache<NSString, UIImage>()
    private var missing: Set<String> = []
    private var inFlight: [String: Task<UIImage?, Never>] = [:]
    private let folder = FileManager.default
        .urls(for: .cachesDirectory, in: .userDomainMask)[0]
        .appendingPathComponent("BankLogos", isDirectory: true)

    /// The logo for a directory domain, or nil (no logo, offline, server error).
    func logo(for domain: String) async -> UIImage? {
        let key = domain.lowercased()
        if let image = memory.object(forKey: key as NSString) { return image }
        if missing.contains(key) { return nil }
        if let task = inFlight[key] { return await task.value }

        let task = Task { await load(key) }
        inFlight[key] = task
        let image = await task.value
        inFlight[key] = nil
        return image
    }

    private func load(_ key: String) async -> UIImage? {
        try? FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        let file = folder.appendingPathComponent("\(key).png")
        let missingMarker = folder.appendingPathComponent("\(key).missing")

        if let age = age(of: missingMarker), age < Self.missingLifetime {
            missing.insert(key)
            return nil
        }

        // Logo already on the device: use it; refresh it only once it is old.
        var stored: UIImage?
        if let age = age(of: file), let data = try? Data(contentsOf: file), let image = UIImage(data: data) {
            memory.setObject(image, forKey: key as NSString)
            if age < Self.logoLifetime { return image }
            stored = image
        }

        var request = URLRequest(url: Self.baseURL.appendingPathComponent(key), timeoutInterval: 8)
        request.setValue("image/png", forHTTPHeaderField: "Accept")
        guard let (data, response) = try? await Self.session.data(for: request),
              let http = response as? HTTPURLResponse
        else { return stored }                       // offline: keep what we have

        switch http.statusCode {
        case 200:
            guard let image = UIImage(data: data), image.size.width > 10 else { return stored }
            try? data.write(to: file, options: .atomic)
            try? FileManager.default.removeItem(at: missingMarker)
            memory.setObject(image, forKey: key as NSString)
            return image
        case 404:                                    // no logo for this institution
            FileManager.default.createFile(atPath: missingMarker.path, contents: nil)
            try? FileManager.default.removeItem(at: file)
            memory.removeObject(forKey: key as NSString)
            missing.insert(key)
            return nil
        default:                                     // server or quota issue: retry later
            return stored
        }
    }

    /// Forgets every cached logo (Settings ▸ Reset all data): the cache reveals
    /// which institutions the user had.
    func clear() {
        memory.removeAllObjects()
        missing.removeAll()
        try? FileManager.default.removeItem(at: folder)
    }

    private func age(of url: URL) -> TimeInterval? {
        guard let date = (try? FileManager.default.attributesOfItem(atPath: url.path))?[.modificationDate] as? Date
        else { return nil }
        return Date().timeIntervalSince(date)
    }
}

// MARK: - BankLogoView

/// Logo of a financial institution. Shows its monogram immediately (and keeps
/// it while loading, offline, or when no logo exists), then the logo once
/// available. Unknown institutions get a generic building icon.
struct BankLogoView: View {
    let domain: String?
    var size: CGFloat = 36
    var cornerRadius: CGFloat? = nil

    @State private var logo: UIImage?

    private var radius: CGFloat { cornerRadius ?? size * 0.22 }

    var body: some View {
        Group {
            if let bank = BankDirectory.bank(forDomain: domain) {
                ZStack {
                    monogramView(for: bank)
                    if let logo {
                        ZStack {
                            Color.white
                            Image(uiImage: logo).resizable().scaledToFit()
                        }
                        .transition(.opacity)
                    }
                }
                .accessibilityElement(children: .ignore)
                .accessibilityLabel(bank.localizedName)
                .task(id: bank.domain) {
                    logo = nil
                    guard let d = bank.domain else { return }
                    let image = await BankLogoStore.shared.logo(for: d)
                    withAnimation(.easeIn(duration: 0.2)) { logo = image }
                }
            } else {
                fallbackView
            }
        }
        .frame(width: size, height: size)
        .clipShape(RoundedRectangle(cornerRadius: radius, style: .continuous))
    }

    private func monogramView(for bank: BankInfo) -> some View {
        let label = BankDirectory.monogram(for: bank)
        let hue = BankDirectory.monogramHue(for: bank.domain ?? bank.id)
        return ZStack {
            // Brightness 0.46 keeps white text at ≥ 4.8:1 contrast for every hue
            // (WCAG AA), including yellows and light greens.
            RoundedRectangle(cornerRadius: radius, style: .continuous)
                .fill(Color(hue: hue, saturation: 0.55, brightness: 0.46))
            Text(label)
                .font(.system(size: size * (label.count <= 2 ? 0.40 : 0.30),
                              weight: .bold, design: .rounded))
                .foregroundStyle(.white)
                .lineLimit(1)
                .minimumScaleFactor(0.5)
                .padding(.horizontal, size * 0.08)
        }
    }

    private var fallbackView: some View {
        ZStack {
            RoundedRectangle(cornerRadius: radius, style: .continuous)
                .fill(Color(.tertiarySystemBackground))
            Image(systemName: "building.columns.fill")
                .font(.system(size: size * 0.45))
                .foregroundStyle(Color(.secondaryLabel))
        }
        .accessibilityHidden(true)
    }
}

// MARK: - InstitutionPickerField

/// Drop-in replacement for a plain TextField.
/// Shows the matched bank logo inline; a search button opens the full picker.
/// The user can also type freely — no bank match is required.
struct InstitutionPickerField: View {
    @Binding var text: String
    var placeholder: String = "Institution"
    /// Called when the user selects a known bank from the picker.
    /// Provides the matched BankInfo so the caller can set the logo domain etc.
    var onBankSelected: ((BankInfo) -> Void)? = nil
    /// Restricts the picker to free-tier institutions (CA + US) when false.
    var hasPaidTier: Bool = true

    @State private var showPicker = false

    private var matchedDomain: String? { BankDirectory.domain(for: text) }

    var body: some View {
        HStack(spacing: 10) {
            BankLogoView(domain: matchedDomain, size: 28, cornerRadius: 6)

            TextField(placeholder, text: $text)
                .autocorrectionDisabled()

            Button {
                showPicker = true
            } label: {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(.tint)
                    .font(.body)
            }
            .buttonStyle(.plain)
        }
        .sheet(isPresented: $showPicker) {
            BankPickerSheet(
                selectedName: $text,
                hasPaidTier: hasPaidTier,
                onBankSelected: onBankSelected
            )
        }
    }
}

// MARK: - BankPickerSheet

struct BankPickerSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(LanguageManager.self) private var lang

    @Binding var selectedName: String
    var hasPaidTier: Bool = true
    var onBankSelected: ((BankInfo) -> Void)? = nil

    @State private var query: String = ""

    private var isSearching: Bool { !query.trimmingCharacters(in: .whitespaces).isEmpty }
    private var searchResults: [BankInfo] { BankDirectory.search(query, hasPaidTier: hasPaidTier) }
    private var countries: [String] { BankDirectory.availableCountries(hasPaidTier: hasPaidTier) }

    var body: some View {
        NavigationStack {
            List {
                if isSearching {
                    if searchResults.isEmpty {
                        Section {
                            Button {
                                selectedName = query.trimmingCharacters(in: .whitespaces)
                                dismiss()
                            } label: {
                                HStack(spacing: 12) {
                                    Image(systemName: "pencil.circle.fill")
                                        .font(.title3)
                                        .foregroundStyle(.tint)
                                        .frame(width: 36, height: 36)
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(query.trimmingCharacters(in: .whitespaces))
                                            .foregroundStyle(.primary)
                                        Text(lang["bank.useCustom"])
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                    }
                                }
                            }
                        }
                    } else {
                        Section {
                            ForEach(searchResults) { bank in
                                bankRow(bank)
                            }
                        }
                    }
                } else {
                    ForEach(countries, id: \.self) { code in
                        Section {
                            ForEach(BankDirectory.banks(for: code, hasPaidTier: hasPaidTier)) { bank in
                                bankRow(bank)
                            }
                        } header: {
                            Text(BankDirectory.flag(for: code) + "  " + BankDirectory.countryName(for: code))
                        }
                    }
                }
            }
            .listStyle(.insetGrouped)
            .navigationTitle(lang["label.institution"])
            .navigationBarTitleDisplayMode(.inline)
            .searchable(text: $query, prompt: lang["action.search"])
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button(lang["action.cancel"]) { dismiss() }
                }
            }
        }
    }

    @ViewBuilder
    private func bankRow(_ bank: BankInfo) -> some View {
        Button {
            selectedName = bank.localizedName
            onBankSelected?(bank)
            dismiss()
        } label: {
            HStack(spacing: 12) {
                BankLogoView(domain: bank.domain, size: 36, cornerRadius: 8)

                VStack(alignment: .leading, spacing: 2) {
                    Text(bank.localizedName)
                        .foregroundStyle(.primary)
                        .lineLimit(1)
                    if let alias = bank.aliases.first {
                        Text(alias.uppercased())
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }

                Spacer()

                if bank.localizedName == selectedName || bank.name == selectedName {
                    Image(systemName: "checkmark")
                        .foregroundStyle(.tint)
                        .fontWeight(.semibold)
                }
            }
            .padding(.vertical, 2)
        }
        .buttonStyle(.plain)
    }
}
