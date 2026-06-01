import Testing
import Foundation
@testable import MorseLight

// MARK: - Mock storage (in-memory, no Keychain dependency)

final class MockPINStorage: PINStorage, @unchecked Sendable {
    var store: [String: Data] = [:]

    @discardableResult
    func set(_ data: Data, forKey key: String) -> Bool {
        store[key] = data; return true
    }
    func data(forKey key: String) -> Data? { store[key] }
    func deleteAll() { store.removeAll() }
}

// MARK: - Tests

@Suite("PINManager")
@MainActor
struct PINManagerTests {

    private func make() -> PINManager { PINManager(storage: MockPINStorage()) }
    private let pinA = "123456"
    private let pinB = "654321"

    // MARK: Initial state

    @Test("isSetup is false before any setup")
    func notSetupInitially() {
        #expect(!make().isSetup)
    }

    @Test("failedAttempts is 0 before any setup")
    func noAttemptsInitially() {
        #expect(make().failedAttempts == 0)
    }

    // MARK: Setup validation

    @Test("setup throws pinsMatch when PIN A == PIN B")
    func setupMatchingPins() {
        let mgr = make()
        #expect(throws: PINSetupError.pinsMatch) {
            try mgr.setup(pinA: "111111", pinB: "111111")
        }
    }

    @Test("setup throws invalidLength for short PIN")
    func setupShortPin() {
        let mgr = make()
        #expect(throws: PINSetupError.invalidLength) {
            try mgr.setup(pinA: "123", pinB: "456789")
        }
    }

    @Test("setup succeeds with valid different PINs")
    func setupSucceeds() throws {
        let mgr = make()
        try mgr.setup(pinA: pinA, pinB: pinB)
        #expect(mgr.isSetup)
    }

    @Test("failedAttempts resets to 0 after setup")
    func attemptsResetAfterSetup() throws {
        let mgr = make()
        try mgr.setup(pinA: pinA, pinB: pinB)
        #expect(mgr.failedAttempts == 0)
    }

    // MARK: Verify — PIN A (access)

    @Test("verify with PIN A returns .unlocked")
    func verifyPinAUnlocks() throws {
        let mgr = make()
        try mgr.setup(pinA: pinA, pinB: pinB)
        #expect(mgr.verify(pin: pinA) == .unlocked)
    }

    @Test("verify with PIN A resets failed attempts")
    func verifyPinAResetsAttempts() throws {
        let mgr = make()
        try mgr.setup(pinA: pinA, pinB: pinB)
        // Make a wrong attempt first
        _ = mgr.verify(pin: "000000")
        #expect(mgr.failedAttempts == 1)
        // Correct PIN A
        _ = mgr.verify(pin: pinA)
        #expect(mgr.failedAttempts == 0)
    }

    // MARK: Verify — PIN B (duress)

    @Test("verify with PIN B returns .wiped and clears isSetup")
    func verifyPinBWipes() throws {
        let mgr = make()
        try mgr.setup(pinA: pinA, pinB: pinB)
        let result = mgr.verify(pin: pinB)
        #expect(result == .wiped)
        #expect(!mgr.isSetup)
    }

    // MARK: Verify — wrong PIN

    @Test("verify with wrong PIN returns correct attemptsLeft")
    func verifyWrongPinDecrementsAttempts() throws {
        let mgr = make()
        try mgr.setup(pinA: pinA, pinB: pinB)
        let result = mgr.verify(pin: "000000")
        #expect(result == .wrong(attemptsLeft: 9))
    }

    @Test("successive wrong PINs decrement attemptsLeft")
    func successiveWrongAttempts() throws {
        let mgr = make()
        try mgr.setup(pinA: pinA, pinB: pinB)
        for expected in stride(from: 9, through: 2, by: -1) {
            let r = mgr.verify(pin: "000000")
            #expect(r == .wrong(attemptsLeft: expected))
        }
    }

    // MARK: Wipe on 10 failures

    @Test("10th wrong PIN triggers wipe")
    func tenWrongAttemptsWipes() throws {
        let mgr = make()
        try mgr.setup(pinA: pinA, pinB: pinB)
        var result: PINResult = .wrong(attemptsLeft: 0)
        for _ in 0..<10 {
            result = mgr.verify(pin: "000000")
        }
        #expect(result == .wiped)
        #expect(!mgr.isSetup)
        #expect(mgr.failedAttempts == 0)
    }

    // MARK: wipeAll

    @Test("wipeAll resets isSetup and failedAttempts")
    func wipeAllResetsState() throws {
        let mgr = make()
        try mgr.setup(pinA: pinA, pinB: pinB)
        mgr.wipeAll()
        #expect(!mgr.isSetup)
        #expect(mgr.failedAttempts == 0)
    }

    // MARK: Persistence simulation

    @Test("verify before setup returns .wrong with max attempts")
    func verifyWithoutSetup() {
        let mgr = make()
        let result = mgr.verify(pin: "123456")
        #expect(result == .wrong(attemptsLeft: PINManager.maxAttempts))
    }

    @Test("isSetup reflects Keychain state on re-init")
    func isSetupPersists() throws {
        let storage = MockPINStorage()
        let mgr1 = PINManager(storage: storage)
        try mgr1.setup(pinA: pinA, pinB: pinB)

        // Second manager uses the same storage (simulates app restart)
        let mgr2 = PINManager(storage: storage)
        #expect(mgr2.isSetup)
    }
}
