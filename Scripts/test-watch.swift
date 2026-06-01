#!/usr/bin/env swift
// Watches source directories and re-runs tests on any .swift file change.
import Foundation

// MARK: - Subprocess helpers

@discardableResult
func shell(_ args: String...) -> Int32 {
    let p = Process()
    p.executableURL = URL(fileURLWithPath: "/usr/bin/env")
    p.arguments = args
    try? p.run()
    p.waitUntilExit()
    return p.terminationStatus
}

// MARK: - File snapshot

typealias Snapshot = [String: Date]

func snapshot(in dirs: [String]) -> Snapshot {
    let fm = FileManager.default
    var result = Snapshot()
    for dir in dirs {
        guard let enumerator = fm.enumerator(atPath: dir) else { continue }
        for case let file as String in enumerator where file.hasSuffix(".swift") {
            let path = (dir as NSString).appendingPathComponent(file)
            if let attrs = try? fm.attributesOfItem(atPath: path),
               let mod = attrs[.modificationDate] as? Date {
                result[path] = mod
            }
        }
    }
    return result
}

func hasChanged(_ old: Snapshot, _ new: Snapshot) -> Bool {
    guard old.count == new.count else { return true }
    return new.contains { path, date in old[path] != date }
}

// MARK: - Watch loop

let watchDirs = ["MorseLight", "MorseLightTests", "Sources", "Tests"]
    .filter { FileManager.default.fileExists(atPath: $0) }

func timestamp() -> String {
    let f = DateFormatter()
    f.dateFormat = "HH:mm:ss"
    return f.string(from: Date())
}

func runTests() {
    print("\u{1B}[2J\u{1B}[H", terminator: "") // clear screen
    print("==> [\(timestamp())] Running tests...")
    shell("swift", "test", "--parallel")
    print("\nWatching \(watchDirs.joined(separator: ", "))… (Ctrl+C to stop)")
}

print("Starting watch mode on: \(watchDirs.joined(separator: ", "))")
var last = snapshot(in: watchDirs)
runTests()

while true {
    Thread.sleep(forTimeInterval: 1.5)
    let current = snapshot(in: watchDirs)
    if hasChanged(last, current) {
        last = current
        runTests()
    }
}
