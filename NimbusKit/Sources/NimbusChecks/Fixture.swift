import Foundation

/// Bundled JSON fixtures under `Fixtures/`, captured from the real Open-Meteo APIs.
public enum Fixture {
    public static func url(_ name: String, ext: String = "json") -> URL? {
        Bundle.module.url(forResource: name, withExtension: ext, subdirectory: "Fixtures")
    }

    public static func data(_ name: String, ext: String = "json") throws -> Data {
        guard let url = url(name, ext: ext) else {
            throw CocoaError(.fileNoSuchFile, userInfo: [NSFilePathErrorKey: "Fixtures/\(name).\(ext)"])
        }
        return try Data(contentsOf: url)
    }

    /// Fresh empty directory for persistence checks. Caller may delete it when done.
    public static func temporaryDirectory() throws -> URL {
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("nimbus-checks-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
        return url
    }
}
