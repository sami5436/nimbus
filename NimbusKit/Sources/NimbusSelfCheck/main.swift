import Foundation
import NimbusChecks

// Presubmit runner. Usage: swift run NimbusSelfCheck [suite ...]   (suites: contract core data ui)
let requested = Set(CommandLine.arguments.dropFirst())
let checker = await AllChecks.run(only: requested.isEmpty ? nil : requested)

for failure in checker.failures {
    print("FAIL \(failure)")
}
print("NimbusSelfCheck: \(checker.passCount) passed, \(checker.failures.count) failed")
exit(checker.failures.isEmpty ? 0 : 1)
