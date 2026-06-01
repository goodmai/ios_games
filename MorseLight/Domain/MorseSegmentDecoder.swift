import Foundation

/// Turns a list of on/off `MorseSegment`s into decoded text.
///
/// Channel-agnostic: the unit duration (1 element) is calibrated from the on-spans
/// via K-means (k=2, dot vs dash), then gaps classify intra-character / letter /
/// word boundaries by ITU multiples (1u / 3u / 7u). Shared by the audio and light
/// decoders so the timing logic lives in one place.
struct MorseSegmentDecoder: Sendable {

    var language: MorseLanguage = .english

    func text(from segments: [MorseSegment]) -> String {
        let onDurations = segments.filter { $0.isOn }.map { $0.duration }
        guard !onDurations.isEmpty else { return "" }

        let unit = estimateUnit(from: onDurations)
        guard unit > 0 else { return "" }

        var table: [String: Character] = [:]
        for (ch, code) in MorseCode.table(for: language) where ch != " " { table[code] = ch }

        var result = ""
        var currentCode = ""

        for seg in segments {
            if seg.isOn {
                // dot threshold = 2× unit (dot ≈ 1u, dash ≈ 3u)
                currentCode += seg.duration < unit * 2.0 ? "." : "-"
            } else {
                if seg.duration > unit * 5.0 {
                    // Word gap (7u): flush letter + space
                    if let ch = table[currentCode] { result.append(ch) }
                    currentCode = ""
                    if !result.hasSuffix(" ") { result += " " }
                } else if seg.duration > unit * 2.0 {
                    // Letter gap (3u): flush letter
                    if let ch = table[currentCode] { result.append(ch) }
                    currentCode = ""
                }
                // else intra-character gap (1u): keep building currentCode
            }
        }

        if !currentCode.isEmpty, let ch = table[currentCode] {
            result.append(ch)
        }

        return result.trimmingCharacters(in: .whitespaces)
    }

    // MARK: Calibrate unit duration via K-means (k=2)

    private func estimateUnit(from onDurations: [TimeInterval]) -> TimeInterval {
        guard !onDurations.isEmpty else { return 0.1 }
        guard onDurations.count > 1 else { return onDurations[0] }

        let sorted = onDurations.sorted()

        var c1 = sorted.first!
        var c2 = sorted.last!

        for _ in 0..<20 {
            let mid = (c1 + c2) / 2.0
            let dots = sorted.filter { $0 <= mid }
            let dashes = sorted.filter { $0 > mid }
            if dots.isEmpty || dashes.isEmpty { break }
            let newC1 = dots.reduce(0, +) / Double(dots.count)
            let newC2 = dashes.reduce(0, +) / Double(dashes.count)
            if abs(newC1 - c1) < 0.001 && abs(newC2 - c2) < 0.001 { break }
            c1 = newC1; c2 = newC2
        }
        return c1   // dot cluster mean = 1 unit
    }
}
</content>
