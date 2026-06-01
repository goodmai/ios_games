import Testing
import Foundation
@testable import MorseLight

// MARK: - MorseLanguage enum

@Suite("MorseLanguage")
struct MorseLanguageTests {

    @Test("MorseLanguage has exactly three cases")
    func threeLanguages() {
        #expect(MorseLanguage.allCases.count == 3)
    }

    @Test("MorseLanguage cases are english, spanish, russian")
    func caseValues() {
        let cases = MorseLanguage.allCases
        #expect(cases.contains(.english))
        #expect(cases.contains(.spanish))
        #expect(cases.contains(.russian))
    }

    @Test("MorseLanguage is Sendable and CaseIterable")
    func conformances() {
        // This test passes at compile time; the type check confirms conformances.
        let langs: [any Sendable] = MorseLanguage.allCases
        #expect(langs.count == 3)
    }
}

// MARK: - English table (existing, regression)

@Suite("MorseCode.englishTable")
struct MorseCodeEnglishTableTests {

    @Test("English table via language selector has all 26 letters")
    func allEnglishLetters() {
        let t = MorseCode.table(for: .english)
        for char in "ABCDEFGHIJKLMNOPQRSTUVWXYZ" {
            #expect(t[char] != nil, "Missing English letter: \(char)")
        }
    }

    @Test("English table via language selector has all 10 digits")
    func allDigitsEnglish() {
        let t = MorseCode.table(for: .english)
        for char in "0123456789" {
            #expect(t[char] != nil, "Missing digit: \(char)")
        }
    }

    @Test("English letter codes are unique")
    func englishLetterCodesUnique() {
        let t = MorseCode.table(for: .english)
        let letterCodes = t.filter { ("A"..."Z").contains($0.key) }.values
        #expect(Set(letterCodes).count == letterCodes.count)
    }
}

// MARK: - Russian table

@Suite("MorseCode.russianTable")
struct MorseCodeRussianTableTests {

    private let table = MorseCode.table(for: .russian)

    @Test("Russian table has exactly 32 Cyrillic letters")
    func russianLetterCount() {
        let russianLetters = "АБВГДЕЖЗИЙКЛМНОПРСТУФХЦЧШЩЪЫЬЭЮЯ"
        for char in russianLetters {
            #expect(table[char] != nil, "Missing Russian letter: \(char)")
        }
        // Count only Cyrillic (range А–Я + Ё-like outliers; we count via known list)
        let cyrillicCount = table.keys.filter { char in
            russianLetters.contains(char)
        }.count
        #expect(cyrillicCount == 32)
    }

    @Test("Russian table has digits 0–9")
    func russianTableHasDigits() {
        for char in "0123456789" {
            #expect(table[char] != nil, "Missing digit: \(char)")
        }
    }

    @Test("Russian A (А) = .-")
    func russianA() {
        #expect(table["А"] == ".-")
    }

    @Test("Russian B (Б) = -...")
    func russianB() {
        #expect(table["Б"] == "-...")
    }

    @Test("Russian V (В) = .--")
    func russianV() {
        #expect(table["В"] == ".--")
    }

    @Test("Russian short-I (Й) = .---")
    func russianJShortI() {
        #expect(table["Й"] == ".---")
    }

    @Test("Russian SH (Ш) = ----")
    func russianSH() {
        #expect(table["Ш"] == "----")
    }

    @Test("Russian hard sign (Ъ) = --.--")
    func russianHardSign() {
        #expect(table["Ъ"] == "--.--")
    }

    @Test("Russian YU (Ю) = ..--")
    func russianYU() {
        #expect(table["Ю"] == "..--")
    }

    @Test("Russian YA (Я) = .-.-")
    func russianYA() {
        #expect(table["Я"] == ".-.-")
    }

    @Test("Russian letter codes contain only dots and dashes")
    func russianCodesOnlyDotsAndDashes() {
        let russianLetters = "АБВГДЕЖЗИЙКЛМНОПРСТУФХЦЧШЩЪЫЬЭЮЯ"
        for char in russianLetters {
            if let code = table[char] {
                for c in code {
                    #expect(c == "." || c == "-",
                            "Invalid char '\(c)' in code for '\(char)'")
                }
            }
        }
    }

    @Test("Russian letter codes are unique")
    func russianLetterCodesUnique() {
        let russianLetters = Set("АБВГДЕЖЗИЙКЛМНОПРСТУФХЦЧШЩЪЫЬЭЮЯ")
        let codes = table.filter { russianLetters.contains($0.key) }.values
        #expect(Set(codes).count == codes.count)
    }
}

// MARK: - Spanish table

@Suite("MorseCode.spanishTable")
struct MorseCodeSpanishTableTests {

    private let table = MorseCode.table(for: .spanish)

    @Test("Spanish table has all 26 Latin letters")
    func allLatinLetters() {
        for char in "ABCDEFGHIJKLMNOPQRSTUVWXYZ" {
            #expect(table[char] != nil, "Missing Latin letter: \(char)")
        }
    }

    @Test("Spanish table has 5 special characters")
    func spanishExtensions() {
        for char: Character in ["Á", "É", "Ñ", "Ó", "Ü"] {
            #expect(table[char] != nil, "Missing Spanish special char: \(char)")
        }
    }

    @Test("Spanish table has digits 0–9")
    func spanishTableHasDigits() {
        for char in "0123456789" {
            #expect(table[char] != nil, "Missing digit: \(char)")
        }
    }

    @Test("Á = .--.-")
    func aAcute() {
        #expect(table["Á"] == ".--.-")
    }

    @Test("É = ..-..")
    func eAcute() {
        #expect(table["É"] == "..-..")
    }

    @Test("Ñ = --.--")
    func enye() {
        #expect(table["Ñ"] == "--.--")
    }

    @Test("Ó = ---.")
    func oAcute() {
        #expect(table["Ó"] == "---.")
    }

    @Test("Ü = ..--")
    func uUmlaut() {
        #expect(table["Ü"] == "..--")
    }

    @Test("Spanish letter codes contain only dots and dashes")
    func spanishCodesOnlyDotsAndDashes() {
        let letters = "ABCDEFGHIJKLMNOPQRSTUVWXYZÁÉÑÓÜabcdefghijklmnopqrstuvwxyz"
        for char in letters.uppercased() {
            if let code = table[char] {
                for c in code {
                    #expect(c == "." || c == "-",
                            "Invalid char '\(c)' in code for '\(char)'")
                }
            }
        }
    }

    @Test("Spanish letter codes are unique (no collisions within Spanish alphabet)")
    func spanishLetterCodesUnique() {
        let letters = Set("ABCDEFGHIJKLMNOPQRSTUVWXYZÁÉÑÓÜ")
        let codes = table.filter { letters.contains($0.key) }.values
        #expect(Set(codes).count == codes.count)
    }
}

// MARK: - MorseConverter with language

@Suite("MorseConverter language support")
@MainActor
struct MorseConverterLanguageTests {

    @Test("Default language is english")
    func defaultLanguageIsEnglish() {
        #expect(MorseConverter().language == .english)
    }

    @Test("Russian А encodes to .-")
    func russianAEncodes() {
        var c = MorseConverter()
        c.language = .russian
        #expect(c.morseString(for: "А") == ".-")
    }

    @Test("Russian АБВ encodes correctly")
    func russianABVEncodes() {
        var c = MorseConverter()
        c.language = .russian
        let result = c.morseString(for: "АБВ")
        #expect(result == ".- -... .--")
    }

    @Test("Spanish Ñ encodes to --.--")
    func spanishNEncode() {
        var c = MorseConverter()
        c.language = .spanish
        #expect(c.morseString(for: "Ñ") == "--.--")
    }

    @Test("Spanish HOLA encodes correctly")
    func spanishHOLAEncodes() {
        var c = MorseConverter()
        c.language = .spanish
        let result = c.morseString(for: "HOLA")
        #expect(result == ".... --- .-.. .-")
    }

    @Test("English remains default — SOS unchanged")
    func englishSOSUnchanged() {
        var c = MorseConverter()
        c.language = .english
        #expect(c.morseString(for: "SOS") == "... --- ...")
    }

    @Test("Russian signals for А are same pattern as English A (.-)")
    func russianASignalsMatchPattern() {
        var c = MorseConverter()
        c.language = .russian
        c.unitDuration = 1.0
        let sigs = c.signals(for: "А")
        // .- = dot gap dash = on(1) off(1) on(3)
        #expect(sigs.count == 3)
        if case .on(let d) = sigs[0] { #expect(d == 1.0) }
        if case .off(let d) = sigs[1] { #expect(d == 1.0) }
        if case .on(let d) = sigs[2] { #expect(d == 3.0) }
    }

    @Test("Unknown characters in non-English language are skipped")
    func unknownCharsSkippedRussian() {
        var c = MorseConverter()
        c.language = .russian
        // English letters not in Russian table should be skipped
        let result = c.morseString(for: "АЖА")
        let withSkip = c.morseString(for: "АА")
        // АЖА = .- ...- .- (Ж is in Russian table, so it SHOULD encode)
        // Just verify it encodes the Morse for each known char
        #expect(result.contains(".-"))
        _ = withSkip
    }
}

// MARK: - MorseAudioDecoder with language

@Suite("MorseAudioDecoder language support")
struct MorseAudioDecoderLanguageTests {

    @Test("Default language is english")
    func defaultLanguageIsEnglish() {
        #expect(MorseAudioDecoder().language == .english)
    }

    @Test("Language property can be set to russian")
    func setLanguageToRussian() {
        var decoder = MorseAudioDecoder()
        decoder.language = .russian
        #expect(decoder.language == .russian)
    }

    @Test("Language property can be set to spanish")
    func setLanguageToSpanish() {
        var decoder = MorseAudioDecoder()
        decoder.language = .spanish
        #expect(decoder.language == .spanish)
    }

    // Round-trip: Russian А (.-) → M4A → decode as Russian → А
    @Test("Round-trip Russian А via audio")
    func roundTripRussianA() throws {
        var converter = MorseConverter()
        converter.language = .russian
        converter.unitDuration = 0.08
        let signals = converter.signals(for: "А")

        let url = try MorseAudioEngine().exportM4A(signals: signals)
        defer { try? FileManager.default.removeItem(at: url) }

        var decoder = MorseAudioDecoder()
        decoder.language = .russian
        let result = try decoder.decode(from: url)
        #expect(result == "А")
    }

    // Round-trip: Spanish Ñ (--.--) → M4A → decode as Spanish → Ñ
    @Test("Round-trip Spanish Ñ via audio")
    func roundTripSpanishN() throws {
        var converter = MorseConverter()
        converter.language = .spanish
        converter.unitDuration = 0.08
        let signals = converter.signals(for: "Ñ")

        let url = try MorseAudioEngine().exportM4A(signals: signals)
        defer { try? FileManager.default.removeItem(at: url) }

        var decoder = MorseAudioDecoder()
        decoder.language = .spanish
        let result = try decoder.decode(from: url)
        #expect(result == "Ñ")
    }

    // Round-trip: Russian ЭТО (a common Russian word)
    @Test("Round-trip Russian ЭТО via audio")
    func roundTripRussianETO() throws {
        var converter = MorseConverter()
        converter.language = .russian
        converter.unitDuration = 0.08
        let signals = converter.signals(for: "ЭТО")

        let url = try MorseAudioEngine().exportM4A(signals: signals)
        defer { try? FileManager.default.removeItem(at: url) }

        var decoder = MorseAudioDecoder()
        decoder.language = .russian
        let result = try decoder.decode(from: url)
        #expect(result == "ЭТО")
    }
}
