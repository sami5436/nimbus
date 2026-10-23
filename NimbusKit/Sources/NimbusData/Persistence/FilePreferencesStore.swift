import Foundation
import NimbusCore

/// `<directory>/preferences.json`. Missing or unreadable file reads as `UnitPreferences.default`.
public actor FilePreferencesStore: PreferencesStore {
    private let directory: URL

    public init(directory: URL) {
        self.directory = directory
    }

    public func loadPreferences() async -> UnitPreferences {
        // STUB(feat/data)
        .default
    }

    public func savePreferences(_ preferences: UnitPreferences) async {
        // STUB(feat/data)
    }
}
