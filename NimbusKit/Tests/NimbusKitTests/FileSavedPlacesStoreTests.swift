import Foundation
import Testing
import NimbusChecks
import NimbusCore
import NimbusData

@Suite("FileSavedPlacesStore")
struct FileSavedPlacesStoreTests {
    let directory: URL
    var file: URL { directory.appendingPathComponent("places.json") }

    init() throws {
        directory = try Fixture.temporaryDirectory()
    }

    static let places = [
        Place(id: "5341145", name: "Cupertino", region: "California", country: "United States",
              coordinate: Coordinate(latitude: 37.323, longitude: -122.03218),
              timeZoneIdentifier: "America/Los_Angeles"),
        Place(id: "1", name: "Berlin", coordinate: Coordinate(latitude: 52.52, longitude: 13.405)),
    ]

    @Test func missingFileReadsAsEmptyList() async throws {
        defer { try? FileManager.default.removeItem(at: directory) }
        let loaded = try await FileSavedPlacesStore(directory: directory).loadPlaces()
        #expect(loaded.isEmpty)
    }

    @Test func missingDirectoryReadsAsEmptyList() async throws {
        let missing = directory.appendingPathComponent("never-created")
        defer { try? FileManager.default.removeItem(at: directory) }
        let loaded = try await FileSavedPlacesStore(directory: missing).loadPlaces()
        #expect(loaded.isEmpty)
    }

    @Test func unreadableFileThrowsInsteadOfReadingAsEmpty() async throws {
        defer { try? FileManager.default.removeItem(at: directory) }
        // A directory where the file should be exists but cannot be read as data.
        try FileManager.default.createDirectory(at: file, withIntermediateDirectories: true)
        let store = FileSavedPlacesStore(directory: directory)
        await #expect {
            try await store.loadPlaces()
        } throws: { error in
            guard case .unknown(let message) = error as? WeatherError else { return false }
            return message.contains("places.json")
        }
    }

    @Test func corruptFileThrowsDecoding() async throws {
        defer { try? FileManager.default.removeItem(at: directory) }
        try Data("not json".utf8).write(to: file)
        let store = FileSavedPlacesStore(directory: directory)
        await #expect(throws: WeatherError.decoding) {
            try await store.loadPlaces()
        }
    }

    @Test func saveThenLoadRoundTripsInOrder() async throws {
        defer { try? FileManager.default.removeItem(at: directory) }
        let store = FileSavedPlacesStore(directory: directory)
        try await store.savePlaces(Self.places)
        #expect(try await store.loadPlaces() == Self.places)
    }

    @Test func saveCreatesMissingDirectory() async throws {
        let nested = directory.appendingPathComponent("a/b", isDirectory: true)
        defer { try? FileManager.default.removeItem(at: directory) }
        try await FileSavedPlacesStore(directory: nested).savePlaces(Self.places)
        #expect(FileManager.default.fileExists(atPath: nested.appendingPathComponent("places.json").path))
    }
}
