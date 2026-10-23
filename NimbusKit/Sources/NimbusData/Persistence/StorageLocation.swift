import Foundation

public enum StorageLocation {
    /// Application Support/Nimbus, created if missing. All Nimbus files live under here.
    public static func defaultDirectory() throws -> URL {
        // STUB(feat/data)
        FileManager.default.temporaryDirectory.appendingPathComponent("Nimbus", isDirectory: true)
    }
}
