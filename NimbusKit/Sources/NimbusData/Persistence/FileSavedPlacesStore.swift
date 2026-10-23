import Foundation
import NimbusCore

/// `<directory>/places.json`, written atomically. Missing file reads as an empty list.
public actor FileSavedPlacesStore: SavedPlacesStore {
    private let directory: URL

    public init(directory: URL) {
        self.directory = directory
    }

    public func loadPlaces() async throws -> [Place] {
        guard let data = try? Data(contentsOf: fileURL) else { return [] }
        do {
            return try JSONDecoder().decode([Place].self, from: data)
        } catch {
            throw WeatherError.decoding
        }
    }

    public func savePlaces(_ places: [Place]) async throws {
        try JSONFile.write(places, to: fileURL)
    }

    private var fileURL: URL { directory.appendingPathComponent("places.json") }
}
