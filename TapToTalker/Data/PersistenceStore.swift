import Foundation
import UIKit

struct AppSettings: Codable, Equatable, Sendable {
    var vocabularyMode: VocabularyMode
    var cardMode: CardMode
    /// Plain local PIN string; empty means no PIN protection.
    var caregiverPIN: String
    /// First-launch caregiver setup completed.
    var hasCompletedOnboarding: Bool

    static let `default` = AppSettings(
        vocabularyMode: .intermediate,
        cardMode: .default,
        caregiverPIN: "",
        hasCompletedOnboarding: false
    )

    var hasPIN: Bool { !caregiverPIN.isEmpty }

    enum CodingKeys: String, CodingKey {
        case vocabularyMode, cardMode, caregiverPIN
        case hasCompletedOnboarding
    }

    init(
        vocabularyMode: VocabularyMode,
        cardMode: CardMode,
        caregiverPIN: String,
        hasCompletedOnboarding: Bool
    ) {
        self.vocabularyMode = vocabularyMode
        self.cardMode = cardMode
        self.caregiverPIN = caregiverPIN
        self.hasCompletedOnboarding = hasCompletedOnboarding
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        vocabularyMode = try container.decodeIfPresent(VocabularyMode.self, forKey: .vocabularyMode) ?? .intermediate
        cardMode = try container.decodeIfPresent(CardMode.self, forKey: .cardMode) ?? .default
        caregiverPIN = try container.decodeIfPresent(String.self, forKey: .caregiverPIN) ?? ""
        hasCompletedOnboarding = try container.decodeIfPresent(Bool.self, forKey: .hasCompletedOnboarding) ?? true
    }
}

@MainActor
final class PersistenceStore {
    static let shared = PersistenceStore()

    private let settingsURL: URL
    private let overridesURL: URL
    private let imagesDirectory: URL
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()

    private(set) var settings: AppSettings
    private(set) var overrides: [String: CustomCardOverride]

    private init() {
        let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        settingsURL = docs.appendingPathComponent("settings.json")
        overridesURL = docs.appendingPathComponent("custom-cards.json")
        imagesDirectory = docs.appendingPathComponent("CustomCardImages", isDirectory: true)

        try? FileManager.default.createDirectory(at: imagesDirectory, withIntermediateDirectories: true)

        settings = Self.load(AppSettings.self, from: settingsURL, decoder: JSONDecoder()) ?? .default
        overrides = Self.load([String: CustomCardOverride].self, from: overridesURL, decoder: JSONDecoder()) ?? [:]
    }

    func updateSettings(_ update: (inout AppSettings) -> Void) {
        update(&settings)
        save(settings, to: settingsURL)
    }

    func override(for cardID: String) -> CustomCardOverride? {
        overrides[cardID]
    }

    func saveOverride(cardID: String, label: String?, emoji: String?, imageData: Data?) {
        var entry = overrides[cardID] ?? CustomCardOverride()
        if let label {
            let trimmed = label.trimmingCharacters(in: .whitespacesAndNewlines)
            entry.label = trimmed.isEmpty ? nil : trimmed
        }
        if let emoji {
            let trimmed = emoji.trimmingCharacters(in: .whitespacesAndNewlines)
            entry.emoji = trimmed.isEmpty ? nil : trimmed
        }
        if let imageData {
            let fileName = "\(cardID).jpg"
            let url = imagesDirectory.appendingPathComponent(fileName)
            try? imageData.write(to: url, options: .atomic)
            entry.imageFileName = fileName
        }
        overrides[cardID] = entry
        save(overrides, to: overridesURL)
    }

    func clearOverride(cardID: String) {
        if let fileName = overrides[cardID]?.imageFileName {
            let url = imagesDirectory.appendingPathComponent(fileName)
            try? FileManager.default.removeItem(at: url)
        }
        overrides.removeValue(forKey: cardID)
        save(overrides, to: overridesURL)
    }

    func image(for cardID: String) -> UIImage? {
        guard let fileName = overrides[cardID]?.imageFileName else { return nil }
        let url = imagesDirectory.appendingPathComponent(fileName)
        guard let data = try? Data(contentsOf: url) else { return nil }
        return UIImage(data: data)
    }

    func displayLabel(for card: AACCard, cardMode: CardMode) -> String {
        if cardMode.usesCustomContent, let custom = overrides[card.id]?.label, !custom.isEmpty {
            return custom
        }
        return card.label
    }

    func displayEmoji(for card: AACCard, cardMode: CardMode) -> String {
        if cardMode.usesCustomContent, let custom = overrides[card.id]?.emoji, !custom.isEmpty {
            return custom
        }
        return card.emoji
    }

    private func save<T: Encodable>(_ value: T, to url: URL) {
        do {
            let data = try encoder.encode(value)
            try data.write(to: url, options: .atomic)
        } catch {
            #if DEBUG
            print("Persistence save failed: \(error)")
            #endif
        }
    }

    private static func load<T: Decodable>(_ type: T.Type, from url: URL, decoder: JSONDecoder) -> T? {
        guard let data = try? Data(contentsOf: url) else { return nil }
        return try? decoder.decode(type, from: data)
    }
}
