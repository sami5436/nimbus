import Foundation
import NimbusCore
import NimbusData

/// Owned by feat/data.
@MainActor
public enum DataChecks {
    public static func run(_ c: inout Checker) async {
        // TODO(feat/data): fixture decoding, URL building, error mapping, persistence round trips,
        // repository cache and fallback behavior.
    }
}
