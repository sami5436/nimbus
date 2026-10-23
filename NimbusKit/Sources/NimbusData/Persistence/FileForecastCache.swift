import Foundation
import NimbusCore

/// One JSON file per place id under `<directory>/forecasts/`. Corrupt files read as nil.
public actor FileForecastCache: ForecastCache {
    private let directory: URL

    public init(directory: URL) {
        self.directory = directory
    }

    public func forecast(forPlaceID placeID: String) async -> Forecast? {
        JSONFile.read(Forecast.self, from: fileURL(for: placeID))
    }

    public func store(_ forecast: Forecast, forPlaceID placeID: String) async {
        // Best effort: a failed cache write must never fail a refresh.
        try? JSONFile.write(forecast, to: fileURL(for: placeID))
    }

    private func fileURL(for placeID: String) -> URL {
        let allowed = CharacterSet(charactersIn: "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-_")
        let name = placeID.addingPercentEncoding(withAllowedCharacters: allowed) ?? placeID
        return directory.appendingPathComponent("forecasts", isDirectory: true)
            .appendingPathComponent("\(name).json")
    }
}
