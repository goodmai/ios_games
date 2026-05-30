import Foundation

struct MorseConverter: Sendable {
    var unitDuration: TimeInterval = 0.1

    // Human-readable: "... --- ..." with "/" between words
    func morseString(for text: String) -> String {
        let upper = text.uppercased()
        var parts: [String] = []
        for char in upper {
            if char == " " {
                parts.append("/")
            } else if let code = MorseCode.table[char] {
                parts.append(code)
            }
        }
        return parts.joined(separator: " ")
    }

    // Sequence of on/off signals for transmission
    func signals(for text: String) -> [MorseSignal] {
        var result: [MorseSignal] = []
        let words = text.uppercased()
            .split(separator: " ", omittingEmptySubsequences: true)

        for (wordIdx, word) in words.enumerated() {
            let letters = word.compactMap { MorseCode.table[$0] }

            for (letterIdx, code) in letters.enumerated() {
                let elems = Array(code)
                for (elemIdx, el) in elems.enumerated() {
                    switch el {
                    case ".": result.append(.on(duration: unitDuration))
                    case "-": result.append(.on(duration: unitDuration * 3))
                    default: break
                    }
                    if elemIdx < elems.count - 1 {
                        result.append(.off(duration: unitDuration))
                    }
                }
                if letterIdx < letters.count - 1 {
                    result.append(.off(duration: unitDuration * 3))
                }
            }

            if wordIdx < words.count - 1 {
                result.append(.off(duration: unitDuration * 7))
            }
        }
        return result
    }
}
