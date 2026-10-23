import Foundation

/// Tiny assertion recorder. Works without XCTest or Swift Testing so presubmit runs on Command Line Tools.
/// Main-actor isolated: all suites run on the main actor (view models and ImageRenderer need it).
@MainActor
public struct Checker {
    public private(set) var failures: [String] = []
    public private(set) var passCount = 0
    private var suite = ""

    public init() {}

    public mutating func beginSuite(_ name: String) {
        suite = name
    }

    public mutating func expect(
        _ condition: Bool,
        _ message: @autoclosure () -> String = "",
        file: StaticString = #fileID,
        line: UInt = #line
    ) {
        if condition {
            passCount += 1
        } else {
            failures.append("[\(suite)] \(file):\(line) \(message())")
        }
    }

    public mutating func expectEqual<T: Equatable>(
        _ actual: T,
        _ expected: T,
        _ message: @autoclosure () -> String = "",
        file: StaticString = #fileID,
        line: UInt = #line
    ) {
        expect(actual == expected, "expected \(expected), got \(actual). \(message())", file: file, line: line)
    }

    public mutating func expectClose(
        _ actual: Double,
        _ expected: Double,
        tolerance: Double = 1e-6,
        _ message: @autoclosure () -> String = "",
        file: StaticString = #fileID,
        line: UInt = #line
    ) {
        expect(
            abs(actual - expected) <= tolerance,
            "expected \(expected) +/- \(tolerance), got \(actual). \(message())",
            file: file,
            line: line
        )
    }

    /// Runs `body`, records a failure if it throws.
    public mutating func expectNoThrow<T>(
        _ message: @autoclosure () -> String = "",
        file: StaticString = #fileID,
        line: UInt = #line,
        _ body: () async throws -> T
    ) async -> T? {
        do {
            let value = try await body()
            passCount += 1
            return value
        } catch {
            failures.append("[\(suite)] \(file):\(line) unexpected error \(error). \(message())")
            return nil
        }
    }

    /// Runs `body`, records a failure unless it throws an error equal to `expected`.
    public mutating func expectThrows(
        _ expected: WeatherErrorMatch,
        file: StaticString = #fileID,
        line: UInt = #line,
        _ body: () async throws -> Void
    ) async {
        do {
            try await body()
            failures.append("[\(suite)] \(file):\(line) expected \(expected) but nothing was thrown")
        } catch {
            expect(expected.matches(error), "expected \(expected), got \(error)", file: file, line: line)
        }
    }
}

import NimbusCore

/// Matcher for `expectThrows`.
public enum WeatherErrorMatch: Sendable, CustomStringConvertible {
    case exactly(WeatherError)
    case anyWeatherError

    func matches(_ error: any Error) -> Bool {
        guard let error = error as? WeatherError else { return false }
        switch self {
        case .exactly(let expected): return error == expected
        case .anyWeatherError: return true
        }
    }

    public var description: String {
        switch self {
        case .exactly(let error): "\(error)"
        case .anyWeatherError: "any WeatherError"
        }
    }
}
