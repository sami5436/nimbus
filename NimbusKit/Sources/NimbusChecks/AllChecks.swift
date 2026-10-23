import Foundation

/// Every suite, in order. Used by `NimbusSelfCheck` and the Swift Testing target.
@MainActor
public enum AllChecks {
    public static let suites: [(name: String, run: @MainActor (inout Checker) async -> Void)] = [
        ("contract", ContractChecks.run),
        ("core", CoreChecks.run),
        ("data", DataChecks.run),
        ("ui", UIChecks.run),
    ]

    public static func run(only names: Set<String>? = nil) async -> Checker {
        var checker = Checker()
        for suite in suites where names?.contains(suite.name) ?? true {
            checker.beginSuite(suite.name)
            await suite.run(&checker)
        }
        return checker
    }
}
