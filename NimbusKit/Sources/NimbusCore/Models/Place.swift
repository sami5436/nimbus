import Foundation

/// WGS84 coordinate.
public struct Coordinate: Sendable, Hashable, Codable {
    public var latitude: Double
    public var longitude: Double

    public init(latitude: Double, longitude: Double) {
        self.latitude = latitude
        self.longitude = longitude
    }
}

/// A location the user can view weather for. `id` is the cache and persistence key.
public struct Place: Sendable, Hashable, Codable, Identifiable {
    /// Reserved id for the device's current location (resolved by `CurrentLocationProvider`).
    public static let currentLocationID = "current-location"

    /// Open-Meteo geocoding id as a string, or `currentLocationID`.
    public var id: String
    public var name: String
    /// First-level admin area, e.g. "California".
    public var region: String?
    public var country: String?
    public var coordinate: Coordinate
    public var timeZoneIdentifier: String?

    public init(
        id: String,
        name: String,
        region: String? = nil,
        country: String? = nil,
        coordinate: Coordinate,
        timeZoneIdentifier: String? = nil
    ) {
        self.id = id
        self.name = name
        self.region = region
        self.country = country
        self.coordinate = coordinate
        self.timeZoneIdentifier = timeZoneIdentifier
    }

    public var isCurrentLocation: Bool { id == Self.currentLocationID }
}
