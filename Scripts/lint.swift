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

guard commandExists("swiftlint") else {
    fputs("SwiftLint not found. Install with: brew install swiftlint\n", stderr)
    exit(1)
}

print("==> Running SwiftLint...")
let status = shell("swiftlint", "lint", "--config", ".swiftlint.yml")
print("==> Lint complete.")
exit(status)
