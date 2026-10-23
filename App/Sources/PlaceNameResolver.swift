import CoreLocation
import MapKit

/// Names a coordinate for display. MapKit's `MKReverseGeocodingRequest` replaces the deprecated
/// `CLGeocoder` but needs iOS 26; earlier systems and failed lookups get a generic name.
enum PlaceNameResolver {
    static let fallbackName = "Current Location"

    struct Resolved: Sendable {
        var name: String
        var region: String?
        var timeZoneIdentifier: String?
    }

    static func resolve(_ location: CLLocation) async -> Resolved {
        if #available(iOS 26, macOS 26, *) {
            if let resolved = await reverseGeocode(location) { return resolved }
        }
        return Resolved(name: fallbackName, region: nil, timeZoneIdentifier: nil)
    }

    @available(iOS 26, macOS 26, *)
    private static func reverseGeocode(_ location: CLLocation) async -> Resolved? {
        guard let request = MKReverseGeocodingRequest(location: location),
              let item = try? await request.mapItems.first
        else { return nil }
        let representations = item.addressRepresentations
        guard let name = representations?.cityName ?? item.name else { return nil }
        return Resolved(name: name, region: representations?.regionName, timeZoneIdentifier: item.timeZone?.identifier)
    }
}
