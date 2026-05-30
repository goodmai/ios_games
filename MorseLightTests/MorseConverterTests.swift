import Testing
import Foundation
@testable import MorseLight

@Suite("MorseConverter")
struct MorseConverterTests {

    @Test("SOS produces correct Morse string")
    func sosString() {
        let result = MorseConverter().morseString(for: "SOS")
        #expect(result == "... --- ...")
    }

    @Test("Lowercase input is normalised to uppercase")
    func lowercaseNormalised() {
        let c = MorseConverter()
        #expect(c.morseString(for: "hi") == c.morseString(for: "HI"))
    }

    @Test("Words separated by slash in Morse string")
    func wordSeparator() {
        let result = MorseConverter().morseString(for: "HI HO")
        #expect(result.contains("/"))
    }

    @Test("Empty input produces empty Morse string")
    func emptyInputMorseString() {
        #expect(MorseConverter().morseString(for: "").isEmpty)
    }

    @Test("Single dot for letter E")
    func singleLetterE() {
        #expect(MorseConverter().morseString(for: "E") == ".")
    }

    @Test("Signals for E is one on-signal of unit duration")
    func signalsForE() {
        let unit = 1.0
        var c = MorseConverter()
        c.unitDuration = unit
        #expect(c.signals(for: "E") == [.on(duration: unit)])
    }

    @Test("Dash duration is 3x unit")
    func dashDuration() {
        let unit = 1.0
        var c = MorseConverter()
        c.unitDuration = unit
        #expect(c.signals(for: "T") == [.on(duration: unit * 3)])
    }

    @Test("SOS produces correct signal count")
    func sosSignalCount() {
        let sigs = MorseConverter().signals(for: "SOS")
        // S = . gap . gap .   → 5 signals
        // inter-letter gap    → 1 signal
        // O = - gap - gap -   → 5 signals
        // inter-letter gap    → 1 signal
        // S = . gap . gap .   → 5 signals
        // Total: 17
        #expect(sigs.count == 17)
    }

    @Test("Inter-letter gap is 3x unit")
    func interLetterGap() {
        let unit = 1.0
        var c = MorseConverter()
        c.unitDuration = unit
        let sigs = c.signals(for: "ET")  // E=.  gap  T=-
        // Expected: .on(1), .off(3), .on(3)
        #expect(sigs.count == 3)
        if case .off(let d) = sigs[1] {
            #expect(d == unit * 3)
        } else {
            Issue.record("Expected an off-signal between letters")
        }
    }

    @Test("Inter-word gap is 7x unit")
    func interWordGap() {
        let unit = 1.0
        var c = MorseConverter()
        c.unitDuration = unit
        let sigs = c.signals(for: "E E")  // E=.  word-gap  E=.
        // Expected: .on(1), .off(7), .on(1)
        #expect(sigs.count == 3)
        if case .off(let d) = sigs[1] {
            #expect(d == unit * 7)
        } else {
            Issue.record("Expected a word-gap off-signal")
        }
    }

    @Test("Unknown characters are skipped")
    func unknownCharsSkipped() {
        let c = MorseConverter()
        #expect(c.morseString(for: "A#B") == c.morseString(for: "AB"))
    }

    @Test("Digit 1 produces correct Morse code")
    func digitConversion() {
        #expect(MorseConverter().morseString(for: "1") == ".----")
    }

    @Test("Signals are empty for empty text")
    func signalsEmptyForEmptyText() {
        #expect(MorseConverter().signals(for: "").isEmpty)
    }

    @Test("Signals are empty for whitespace-only text")
    func signalsEmptyForWhitespace() {
        #expect(MorseConverter().signals(for: "   ").isEmpty)
    }

    @Test("On signals alternate with off signals within a letter")
    func signalsAlternateWithinLetter() {
        let sigs = MorseConverter().signals(for: "S")  // ... = 3 dots
        // on off on off on
        #expect(sigs.count == 5)
        for (i, sig) in sigs.enumerated() {
            if i % 2 == 0 {
                if case .on = sig { } else { Issue.record("Expected on at index \(i)") }
            } else {
                if case .off = sig { } else { Issue.record("Expected off at index \(i)") }
            }
        }
    }
}

@Suite("MorseCode Table")
struct MorseCodeTableTests {

    @Test("All 26 letters are in the table")
    func allLettersPresent() {
        for char in "ABCDEFGHIJKLMNOPQRSTUVWXYZ" {
            #expect(MorseCode.table[char] != nil, "Missing letter: \(char)")
        }
    }

    @Test("All digits 0–9 are in the table")
    func allDigitsPresent() {
        for char in "0123456789" {
            #expect(MorseCode.table[char] != nil, "Missing digit: \(char)")
        }
    }

    @Test("Every code contains only dots and dashes")
    func codesContainOnlyDotsAndDashes() {
        for (char, code) in MorseCode.table where char != " " {
            for c in code {
                #expect(c == "." || c == "-", "Bad char '\(c)' in code for '\(char)'")
            }
        }
    }

    @Test("No two letters share the same code")
    func codesAreUnique() {
        let codes = MorseCode.table.filter { $0.key != " " }.values
        let unique = Set(codes)
        #expect(codes.count == unique.count)
    }
}
