import Foundation
import NimbusCore

/// `<directory>/preferences.json`. Missing or unreadable file reads as `UnitPreferences.default`.
public actor FilePreferencesStore: PreferencesStore {
    private let directory: URL

    public init(directory: URL) {
        self.directory = directory
    }

    public func loadPreferences() async -> UnitPreferences {
        JSONFile.read(UnitPreferences.self, from: fileURL) ?? .default
    }

    public func savePreferences(_ preferences: UnitPreferences) async {
        try? JSONFile.write(preferences, to: fileURL)
    }

    private var fileURL: URL { directory.appendingPathComponent("preferences.json") }
}
