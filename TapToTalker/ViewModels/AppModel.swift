import Foundation
import Observation
import UIKit

@Observable
@MainActor
final class AppModel {
    var settings: AppSettings
    var overridesVersion: Int = 0

    private let store: PersistenceStore

    init(store: PersistenceStore? = nil) {
        let resolved = store ?? PersistenceStore.shared
        self.store = resolved
        self.settings = resolved.settings
    }

    var vocabularyMode: VocabularyMode {
        get { settings.vocabularyMode }
        set {
            settings.vocabularyMode = newValue
            persistSettings()
        }
    }

    var cardMode: CardMode {
        get { settings.cardMode }
        set {
            settings.cardMode = newValue
            persistSettings()
        }
    }

    var hasPIN: Bool { settings.hasPIN }

    var needsOnboarding: Bool { !settings.hasCompletedOnboarding }

    func validatePIN(_ attempt: String) -> Bool {
        settings.caregiverPIN == attempt
    }

    func saveCaregiverPIN(_ pin: String) {
        settings.caregiverPIN = pin.trimmingCharacters(in: .whitespacesAndNewlines)
        persistSettings()
    }

    func clearPIN() {
        settings.caregiverPIN = ""
        persistSettings()
    }

    func completeOnboarding(
        vocabularyMode: VocabularyMode,
        pin: String
    ) {
        settings.vocabularyMode = vocabularyMode
        settings.caregiverPIN = pin.trimmingCharacters(in: .whitespacesAndNewlines)
        if settings.cardMode == .default, store.overrides.isEmpty == false {
            settings.cardMode = .custom
        }
        settings.hasCompletedOnboarding = true
        persistSettings()
    }

    func displayLabel(for card: AACCard) -> String {
        store.displayLabel(for: card, cardMode: settings.cardMode)
    }

    func displayEmoji(for card: AACCard) -> String {
        store.displayEmoji(for: card, cardMode: settings.cardMode)
    }

    func customImage(for card: AACCard) -> Bool {
        settings.cardMode.usesCustomContent && store.image(for: card.id) != nil
    }

    func image(for cardID: String) -> UIImage? {
        store.image(for: cardID)
    }

    func saveCardOverride(cardID: String, label: String?, emoji: String?, imageData: Data?) {
        store.saveOverride(cardID: cardID, label: label, emoji: emoji, imageData: imageData)
        overridesVersion += 1
    }

    func clearCardOverride(cardID: String) {
        store.clearOverride(cardID: cardID)
        overridesVersion += 1
    }

    func override(for cardID: String) -> CustomCardOverride? {
        store.override(for: cardID)
    }

    private func persistSettings() {
        store.updateSettings { $0 = settings }
        settings = store.settings
    }
}
