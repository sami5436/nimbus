import Testing
import NimbusChecks

// Runs the same suites as `swift run NimbusSelfCheck` under Swift Testing.
// Requires a full Xcode install (`swift test`); `swift build` never compiles this target.
// Add idiomatic per-feature @Test files here once Xcode is available.
@MainActor
struct SelfCheckSuiteTests {
    @Test(arguments: ["contract", "core", "data", "ui"])
    func suitePasses(_ name: String) async {
        let checker = await AllChecks.run(only: [name])
        #expect(checker.failures.isEmpty, "\(checker.failures.joined(separator: "\n"))")
    }
}
