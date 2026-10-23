import Foundation
import NimbusCore

/// `<directory>/places.json`, written atomically. Missing file reads as an empty list.
public actor FileSavedPlacesStore: SavedPlacesStore {
    private let directory: URL

    public init(directory: URL) {
        self.directory = directory
    }

    public func loadPlaces() async throws -> [Place] {
        // STUB(feat/data)
        []
    }

    public func savePlaces(_ places: [Place]) async throws {
        // STUB(feat/data)
    }
}
