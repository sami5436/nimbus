import Foundation
import NimbusCore

public enum StorageLocation {
    /// Application Support/Nimbus, created if missing. All Nimbus files live under here.
    public static func defaultDirectory() throws -> URL {
        do {
            let support = try FileManager.default.url(
                for: .applicationSupportDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
            let directory = support.appendingPathComponent("Nimbus", isDirectory: true)
            try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
            return directory
        } catch {
            throw WeatherError.unknown("Could not create storage directory: \(error.localizedDescription)")
        }
    }
}
