import CryptoKit
import Foundation

// MARK: - Storage abstraction (injectable for tests)

protocol PINStorage: Sendable {
    @discardableResult
    func set(_ data: Data, forKey key: String) -> Bool
    func data(forKey key: String) -> Data?
    func deleteAll()
}

// MARK: - Domain types

enum PINResult: Equatable {
    case unlocked                        // PIN A matched — grant access
    case wiped                           // PIN B entered OR 10 failures — all data erased
    case wrong(attemptsLeft: Int)        // Neither PIN matched
}

enum PINSetupError: Error, LocalizedError {
    case pinsMatch
    case invalidLength
    case storageFailed

    var errorDescription: String? {
        switch self {
        case .pinsMatch:     "Access PIN and Duress PIN must be different"
        case .invalidLength: "PIN must be exactly \(PINManager.pinLength) digits"
        case .storageFailed: "Could not save PIN — please try again"
        }
    }
}

// MARK: - PINManager

@Observable
@MainActor
final class PINManager {

    static let pinLength   = 6
    static let maxAttempts = 10

    private(set) var isSetup:        Bool
    private(set) var failedAttempts: Int

    private let storage: any PINStorage

    // MARK: Keys

    private enum Keys {
        static let hashA    = "pinHashA"
        static let hashB    = "pinHashB"
        static let salt     = "pinSalt"
        static let attempts = "pinAttempts"
    }

    // MARK: Init

    init(storage: any PINStorage = KeychainStore()) {
        self.storage = storage
        self.isSetup = storage.data(forKey: Keys.hashA) != nil
                    && storage.data(forKey: Keys.salt)  != nil
        self.failedAttempts = storage.data(forKey: Keys.attempts)
            .map { Int($0[0]) } ?? 0
    }

    // MARK: Setup

    func setup(pinA: String, pinB: String) throws {
        guard pinA.count == Self.pinLength, pinB.count == Self.pinLength else {
            throw PINSetupError.invalidLength
        }
        guard pinA != pinB else { throw PINSetupError.pinsMatch }

        let salt = Data((0..<32).map { _ in UInt8.random(in: 0...255) })
        let hashA = hash(pinA, salt: salt)
        let hashB = hash(pinB, salt: salt)

        guard storage.set(salt, forKey: Keys.salt),
              storage.set(hashA, forKey: Keys.hashA),
              storage.set(hashB, forKey: Keys.hashB) else {
            throw PINSetupError.storageFailed
        }

        isSetup = true
        failedAttempts = 0
        storage.set(Data([0]), forKey: Keys.attempts)
    }

    // MARK: Verify

    func verify(pin: String) -> PINResult {
        guard isSetup,
              let saltData = storage.data(forKey: Keys.salt),
              let storedA  = storage.data(forKey: Keys.hashA),
              let storedB  = storage.data(forKey: Keys.hashB) else {
            return .wrong(attemptsLeft: Self.maxAttempts)
        }

        let candidate = hash(pin, salt: saltData)

        if candidate == storedA {
            failedAttempts = 0
            storage.set(Data([0]), forKey: Keys.attempts)
            return .unlocked
        }

        if candidate == storedB {
            wipeAll()
            return .wiped
        }

        failedAttempts += 1
        let byte = UInt8(min(failedAttempts, 255))
        storage.set(Data([byte]), forKey: Keys.attempts)

        if failedAttempts >= Self.maxAttempts {
            wipeAll()
            return .wiped
        }

        return .wrong(attemptsLeft: Self.maxAttempts - failedAttempts)
    }

    // MARK: Wipe

    func wipeAll() {
        storage.deleteAll()
        isSetup = false
        failedAttempts = 0

        // Clear all UserDefaults (app settings, seed phrase, etc.)
        if let bundleId = Bundle.main.bundleIdentifier {
            UserDefaults.standard.removePersistentDomain(forName: bundleId)
        }

        // Remove temporary M4A exports
        let tmp = FileManager.default.temporaryDirectory
        if let files = try? FileManager.default.contentsOfDirectory(
            at: tmp, includingPropertiesForKeys: nil
        ) {
            for url in files { try? FileManager.default.removeItem(at: url) }
        }
    }

    // MARK: Private

    private func hash(_ pin: String, salt: Data) -> Data {
        var combined = Data(pin.utf8)
        combined.append(salt)
        return Data(SHA256.hash(data: combined))
    }
}
