import Testing
import Foundation
@testable import MorseLight

@Suite("MorseCipher")
struct MorseCipherTests {

    // MARK: - Round-trip

    @Test("Round-trip restores plaintext", arguments: ["SOS", "A", "HELLO WORLD", "TEST 123"])
    func roundTrip(text: String) throws {
        let ct = try MorseCipher.encrypt(text, seed: "testseed")
        let dt = try MorseCipher.decrypt(ct, seed: "testseed")
        #expect(dt == text)
    }

    @Test("Round-trip with seed 'hello' and phrase 'SOS'")
    func exampleFromSpec() throws {
        let ct = try MorseCipher.encrypt("SOS", seed: "hello")
        let dt = try MorseCipher.decrypt(ct, seed: "hello")
        #expect(dt == "SOS")
    }

    // MARK: - Ciphertext properties

    @Test("Ciphertext contains only uppercase hex characters")
    func ciphertextIsHexOnly() throws {
        let ct = try MorseCipher.encrypt("TEST", seed: "key")
        let allowed = CharacterSet(charactersIn: "0123456789ABCDEF")
        #expect(ct.unicodeScalars.allSatisfy { allowed.contains($0) })
    }

    @Test("Ciphertext length is (12 + N + 16) * 2 hex chars")
    func ciphertextLength() throws {
        // AES-GCM: nonce(12) + plaintext(N) + tag(16) = overhead(28) + N bytes
        // 3-char input ("SOS") → 31 bytes → 62 hex chars
        let ct = try MorseCipher.encrypt("SOS", seed: "key")
        #expect(ct.count == 62)
    }

    @Test("Encryption is non-deterministic (random nonce)")
    func nonDeterministic() throws {
        let c1 = try MorseCipher.encrypt("SOS", seed: "hello")
        let c2 = try MorseCipher.encrypt("SOS", seed: "hello")
        #expect(c1 != c2)
    }

    // MARK: - Wrong seed / tampering

    @Test("Wrong seed fails decryption with MorseCipherError")
    func wrongSeedFails() throws {
        let ct = try MorseCipher.encrypt("SOS", seed: "hello")
        #expect(throws: MorseCipherError.self) {
            try MorseCipher.decrypt(ct, seed: "wrong")
        }
    }

    @Test("Truncated ciphertext throws invalidHexInput or decryptionFailed")
    func truncatedCiphertextFails() throws {
        let ct = try MorseCipher.encrypt("SOS", seed: "key")
        let truncated = String(ct.prefix(4)) // too short for AES-GCM box
        #expect(throws: MorseCipherError.self) {
            try MorseCipher.decrypt(truncated, seed: "key")
        }
    }

    // MARK: - Hex helpers

    @Test("data(fromHex:) parses uppercase hex correctly")
    func hexParseUppercase() {
        let d = MorseCipher.data(fromHex: "DEADBEEF")
        #expect(d == Data([0xDE, 0xAD, 0xBE, 0xEF]))
    }

    @Test("data(fromHex:) parses lowercase hex correctly")
    func hexParseLowercase() {
        let d = MorseCipher.data(fromHex: "deadbeef")
        #expect(d == Data([0xDE, 0xAD, 0xBE, 0xEF]))
    }

    @Test("data(fromHex:) returns nil for odd-length input")
    func hexParseOddLength() {
        #expect(MorseCipher.data(fromHex: "ABC") == nil)
    }

    @Test("data(fromHex:) returns nil for non-hex characters")
    func hexParseInvalidChars() {
        #expect(MorseCipher.data(fromHex: "GHIJ") == nil)
    }

    @Test("hexString round-trips through data(fromHex:)")
    func hexRoundTrip() {
        let original = Data([0x00, 0xFF, 0x42, 0xAB])
        let hex = MorseCipher.hexString(from: original)
        #expect(MorseCipher.data(fromHex: hex) == original)
    }

    // MARK: - Key derivation

    @Test("Same seed always produces the same key (encrypt→decrypt works)")
    func deterministicKey() throws {
        // Encrypt with seed, then decrypt with independently derived key
        let ct = try MorseCipher.encrypt("X", seed: "abc")
        // Decrypt succeeds only if key derivation is deterministic
        let pt = try MorseCipher.decrypt(ct, seed: "abc")
        #expect(pt == "X")
    }

    @Test("Different seeds produce different keys (decrypt fails cross-seed)")
    func differentSeeds() throws {
        let ct = try MorseCipher.encrypt("X", seed: "alpha")
        #expect(throws: MorseCipherError.self) {
            try MorseCipher.decrypt(ct, seed: "beta")
        }
    }
}
