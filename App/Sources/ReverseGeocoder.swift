import CoreLocation
import MapKit

/// Display name for a coordinate. Uses MapKit's reverse geocoding (`CLGeocoder` is deprecated in the
/// iOS 26 SDK). Never throws: a failed lookup still yields a usable "Current Location" label.
enum ReverseGeocoder {
    struct Label: Sendable, Equatable {
        var name: String
        var country: String?

        static let fallback = Label(name: "Current Location", country: nil)
    }

    static func label(for location: CLLocation) async -> Label {
        guard #available(iOS 26, macOS 26, *) else { return .fallback }
        guard let request = MKReverseGeocodingRequest(location: location) else { return .fallback }
        guard let item = try? await request.mapItems.first,
              let representations = item.addressRepresentations
        else { return .fallback }
        let name = representations.cityName ?? item.name
        guard let name, !name.isEmpty else { return .fallback }
        return Label(name: name, country: representations.regionName)
    }
}
