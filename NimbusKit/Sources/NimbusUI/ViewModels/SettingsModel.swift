import Foundation
import Observation
import NimbusCore

/// Unit preferences, persisted. Exposes the formatter every screen uses.
@MainActor
@Observable
public final class SettingsModel {
    public private(set) var preferences: UnitPreferences
    private let store: any PreferencesStore
    private let locale: Locale

    public init(dependencies: AppDependencies, locale: Locale = .current) {
        self.store = dependencies.preferences
        self.preferences = .default
        self.locale = locale
    }

    public var formatter: WeatherFormatter {
        WeatherFormatter(preferences: preferences, locale: locale)
    }

    public func load() async {
        preferences = await store.loadPreferences()
    }

    public func setTemperature(_ unit: TemperatureUnit) async {
        preferences.temperature = unit
        await store.savePreferences(preferences)
    }

    public func setSpeed(_ unit: SpeedUnit) async {
        preferences.speed = unit
        await store.savePreferences(preferences)
    }
}
