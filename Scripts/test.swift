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

print("==> Running Swift tests...")
let status = shell("swift", "test", "--parallel")
print("\n==> Tests complete.")
exit(status)
