import SwiftUI
import NimbusCore

/// App root: pages through current location + saved places, opens the locations list and search.
/// Owns the view models; the app target only constructs this with live `AppDependencies`.
public struct RootView: View {
    private let dependencies: AppDependencies

    public init(dependencies: AppDependencies) {
        self.dependencies = dependencies
    }

    public var body: some View {
        // STUB(feat/screens)
        Text("Nimbus")
    }
}
