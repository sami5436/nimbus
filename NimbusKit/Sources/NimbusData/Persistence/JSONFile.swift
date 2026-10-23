import Foundation
import NimbusCore

/// Shared atomic JSON read and write used by the file stores.
enum JSONFile {
    static func read<T: Decodable>(_ type: T.Type, from url: URL) -> T? {
        guard let data = try? Data(contentsOf: url) else { return nil }
        return try? JSONDecoder().decode(T.self, from: data)
    }

    static func write<T: Encodable>(_ value: T, to url: URL) throws {
        do {
            try FileManager.default.createDirectory(
                at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
            try JSONEncoder().encode(value).write(to: url, options: .atomic)
        } catch {
            throw WeatherError.unknown("Could not write \(url.lastPathComponent): \(error.localizedDescription)")
        }
    }
}
