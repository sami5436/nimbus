import Foundation
import SwiftUI
import ImageIO
import UniformTypeIdentifiers

/// Offscreen render of a SwiftUI view with `ImageRenderer`. This is the visual check while there is
/// no Xcode (no previews, no simulator). Set `NIMBUS_SNAPSHOT_DIR=/some/dir` to also write PNGs
/// that a human or agent can open and inspect.
@MainActor
public enum Snapshot {
    /// Returns the rendered pixel size, or nil if rendering failed.
    @discardableResult
    public static func render<V: View>(
        _ view: V,
        name: String,
        size: CGSize = CGSize(width: 390, height: 844),
        colorScheme: ColorScheme = .dark
    ) -> CGSize? {
        let content = view
            .frame(width: size.width, height: size.height)
            .environment(\.colorScheme, colorScheme)
        let renderer = ImageRenderer(content: content)
        renderer.scale = 2
        guard let image = renderer.cgImage else { return nil }
        if let directory = ProcessInfo.processInfo.environment["NIMBUS_SNAPSHOT_DIR"] {
            write(image, to: URL(fileURLWithPath: directory).appendingPathComponent("\(name).png"))
        }
        return CGSize(width: image.width, height: image.height)
    }

    private static func write(_ image: CGImage, to url: URL) {
        try? FileManager.default.createDirectory(
            at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
        guard let destination = CGImageDestinationCreateWithURL(
            url as CFURL, UTType.png.identifier as CFString, 1, nil)
        else { return }
        CGImageDestinationAddImage(destination, image, nil)
        CGImageDestinationFinalize(destination)
    }
}
