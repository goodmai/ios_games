import Foundation

// MARK: - Language selection

enum MorseLanguage: String, CaseIterable, Sendable, Equatable {
    case english = "English"
    case spanish = "Español"
    case russian = "Русский"

    var flagEmoji: String {
        switch self {
        case .english: "🇬🇧"
        case .spanish: "🇪🇸"
        case .russian: "🇷🇺"
        }
    }
}

// MARK: - Signal type

enum MorseSignal: Equatable, Sendable {
    case on(duration: TimeInterval)
    case off(duration: TimeInterval)
}

// MARK: - Morse code tables

enum MorseCode {

    // Digits and punctuation shared by all languages
    private static let sharedTable: [Character: String] = [
        "0": "-----", "1": ".----", "2": "..---", "3": "...--",
        "4": "....-", "5": ".....", "6": "-....", "7": "--...",
        "8": "---..", "9": "----.",
        ".": ".-.-.-", ",": "--..--", "?": "..--..",
        "!": "-.-.--", "/": "-..-.",  "@": ".--.-.", " ": "/"
    ]

    // MARK: English (ITU-R M.1677-1)

    static let table: [Character: String] = [
        "A": ".-",    "B": "-...",  "C": "-.-.",  "D": "-..",
        "E": ".",     "F": "..-.",  "G": "--.",   "H": "....",
        "I": "..",    "J": ".---",  "K": "-.-",   "L": ".-..",
        "M": "--",    "N": "-.",    "O": "---",   "P": ".--.",
        "Q": "--.-",  "R": ".-.",   "S": "...",   "T": "-",
        "U": "..-",   "V": "...-",  "W": ".--",   "X": "-..-",
        "Y": "-.--",  "Z": "--..",
        "0": "-----", "1": ".----", "2": "..---", "3": "...--",
        "4": "....-", "5": ".....", "6": "-....", "7": "--...",
        "8": "---..", "9": "----.",
        ".": ".-.-.-", ",": "--..--", "?": "..--..",
        "!": "-.-.--", "/": "-..-.",  "@": ".--.-.", " ": "/"
    ]

    // MARK: Russian (ITU-R M.1677-1)

    static let russianLetters: [Character: String] = [
        "А": ".-",    "Б": "-...",  "В": ".--",   "Г": "--.",
        "Д": "-..",   "Е": ".",     "Ж": "...-",  "З": "--..",
        "И": "..",    "Й": ".---",  "К": "-.-",   "Л": ".-..",
        "М": "--",    "Н": "-.",    "О": "---",   "П": ".--.",
        "Р": ".-.",   "С": "...",   "Т": "-",     "У": "..-",
        "Ф": "..-.",  "Х": "....",  "Ц": "-.-.",  "Ч": "---.",
        "Ш": "----",  "Щ": "--.-",  "Ъ": "--.--", "Ы": "-.--",
        "Ь": "-..-",  "Э": "..-..","Ю": "..--",   "Я": ".-.-",
    ]

    // MARK: Spanish (ITU-R M.1677-1 + Spanish extensions)

    static let spanishLetters: [Character: String] = [
        "A": ".-",    "B": "-...",  "C": "-.-.",  "D": "-..",
        "E": ".",     "F": "..-.",  "G": "--.",   "H": "....",
        "I": "..",    "J": ".---",  "K": "-.-",   "L": ".-..",
        "M": "--",    "N": "-.",    "O": "---",   "P": ".--.",
        "Q": "--.-",  "R": ".-.",   "S": "...",   "T": "-",
        "U": "..-",   "V": "...-",  "W": ".--",   "X": "-..-",
        "Y": "-.--",  "Z": "--..",
        // Spanish-specific extensions
        "Á": ".--.-", "É": "..-..","Ñ": "--.--",  "Ó": "---.", "Ü": "..--",
    ]

    // MARK: Language dispatch

    static func table(for language: MorseLanguage) -> [Character: String] {
        switch language {
        case .english:
            return table
        case .russian:
            return russianLetters.merging(sharedTable) { existing, _ in existing }
        case .spanish:
            return spanishLetters.merging(sharedTable) { existing, _ in existing }
        }
    }
}
