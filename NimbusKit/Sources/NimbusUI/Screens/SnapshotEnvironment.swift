import SwiftUI

private struct IsSnapshotKey: EnvironmentKey {
    static let defaultValue = false
}

extension EnvironmentValues {
    /// True only while rendering offscreen snapshots. `ImageRenderer` cannot draw `ScrollView` content,
    /// so views swap scrolling containers for plain stacks. Never set at runtime.
    public var isSnapshot: Bool {
        get { self[IsSnapshotKey.self] }
        set { self[IsSnapshotKey.self] = newValue }
    }
}
