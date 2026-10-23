import Foundation
import NimbusCore

/// One JSON file per place id under `<directory>/forecasts/`. Corrupt files read as nil.
public actor FileForecastCache: ForecastCache {
    private let directory: URL

    public init(directory: URL) {
        self.directory = directory
    }

    public func forecast(forPlaceID placeID: String) async -> Forecast? {
        // STUB(feat/data)
        nil
    }

    public func store(_ forecast: Forecast, forPlaceID placeID: String) async {
        // STUB(feat/data)
    }
}
