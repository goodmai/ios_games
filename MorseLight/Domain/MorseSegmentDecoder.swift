import Foundation

/// Turns a list of on/off `MorseSegment`s into decoded text.
///
/// Channel-agnostic: the unit duration (1 element) is calibrated from the on-spans
/// via K-means (k=2, dot vs dash), then gaps classify intra-character / letter /
/// word boundaries by ITU multiples (1u / 3u / 7u). Shared by the audio and light
/// decoders so the timing logic lives in one place.
struct MorseSegmentDecoder: Sendable {

    var language: MorseLanguage = .english

    /// Convergence threshold for the dot/dash k-means calibration: the loop stops
    /// once the largest centroid shift drops below this (Δμ < ε).
    var convergenceEpsilon: Double = 0.0005
    var maxIterations: Int = 50

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
        let kmeans = KMeans1D(epsilon: convergenceEpsilon, maxIterations: maxIterations)
        guard let clusters = kmeans.cluster(onDurations) else { return 0.1 }
        return clusters.low   // dot cluster mean = 1 unit
    }
}
</content>
