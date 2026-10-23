import CoreLocation
import NimbusCore
import Testing
@testable import Nimbus

struct LocationMappingTests {
    @Test func deniedMapsToPermissionDenied() {
        #expect(LocationAuthorizer.error(for: .denied) == .locationPermissionDenied)
    }

    @Test func restrictedAndUndecidedMapToUnavailable() {
        #expect(LocationAuthorizer.error(for: .restricted) == .locationUnavailable)
        #expect(LocationAuthorizer.error(for: .notDetermined) == .locationUnavailable)
    }

    @Test func authorizedMapsToNoError() {
        #expect(LocationAuthorizer.error(for: .authorizedWhenInUse) == nil)
        #expect(LocationAuthorizer.error(for: .authorizedAlways) == nil)
    }

    @Test func labelPrefersCityThenItemName() {
        #expect(ReverseGeocoder.Label.make(cityName: "Cupertino", itemName: "Apple Park", regionName: "United States")
            == .init(name: "Cupertino", country: "United States"))
        #expect(ReverseGeocoder.Label.make(cityName: nil, itemName: "Apple Park", regionName: nil)
            == .init(name: "Apple Park", country: nil))
        #expect(ReverseGeocoder.Label.make(cityName: "", itemName: "Apple Park", regionName: "")
            == .init(name: "Apple Park", country: nil))
    }

    @Test func labelFallsBackWhenNothingNamed() {
        #expect(ReverseGeocoder.Label.make(cityName: nil, itemName: nil, regionName: "France") == .fallback)
        #expect(ReverseGeocoder.Label.make(cityName: "", itemName: "", regionName: nil) == .fallback)
    }
}
