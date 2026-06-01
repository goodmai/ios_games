#!/usr/bin/env swift
import Foundation

@discardableResult
func shell(_ args: String...) -> Int32 {
    let p = Process()
    p.executableURL = URL(fileURLWithPath: "/usr/bin/env")
    p.arguments = args
    try? p.run()
    p.waitUntilExit()
    return p.terminationStatus
}

func commandExists(_ name: String) -> Bool {
    let p = Process()
    p.executableURL = URL(fileURLWithPath: "/usr/bin/env")
    p.arguments = ["which", name]
    p.standardOutput = FileHandle.nullDevice
    p.standardError = FileHandle.nullDevice
    try? p.run()
    p.waitUntilExit()
    return p.terminationStatus == 0
}

func capture(_ args: String...) -> String {
    let p = Process()
    let pipe = Pipe()
    p.executableURL = URL(fileURLWithPath: "/usr/bin/env")
    p.arguments = args
    p.standardOutput = pipe
    try? p.run()
    p.waitUntilExit()
    return String(data: pipe.fileHandleForReading.readDataToEndOfFile(), encoding: .utf8)?
        .trimmingCharacters(in: .newlines) ?? ""
}

print("==> MorseLight setup")

let swiftVersion = capture("swift", "--version")
print("Swift: \(swiftVersion)")

print("\n==> Resolving Swift Package dependencies...")
let resolveStatus = shell("swift", "package", "resolve")
guard resolveStatus == 0 else {
    fputs("ERROR: Package resolution failed.\n", stderr)
    exit(resolveStatus)
}

if !commandExists("swiftlint") {
    print("\nWARNING: SwiftLint not found. Install with: brew install swiftlint")
}

print("""

Setup complete. Quick commands:
  swift test                        - run all tests
  swift Scripts/test.swift          - run tests (verbose)
  swift Scripts/lint.swift          - run linter
  swift Scripts/test-watch.swift    - watch mode
""")
