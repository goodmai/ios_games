import CryptoKit
import Foundation

enum MorseCipherError: Error, LocalizedError {
    case encryptionFailed
    case decryptionFailed(String)
    case invalidHexInput

    var errorDescription: String? {
        switch self {
        case .encryptionFailed:           "Encryption failed"
        case .decryptionFailed(let msg):  "Decryption failed: \(msg)"
        case .invalidHexInput:            "Invalid ciphertext — expected uppercase hex"
        }
    }
}

/// AES-256-GCM cipher whose key is derived from a seed phrase via SHA-256.
///
/// Ciphertext format: nonce (12 B) ++ ciphertext (N B) ++ tag (16 B) — all
/// encoded as uppercase hex so the result can be transmitted as Morse code
/// (only characters 0–9 and A–F, which all have ITU Morse encodings).
///
/// The random nonce means the same plaintext never produces the same ciphertext,
/// and AES-GCM authentication tags detect any bit flip (wrong seed or tampering
/// throws `MorseCipherError.decryptionFailed`).
struct MorseCipher: Sendable {

    // MARK: Public API

    static func encrypt(_ text: String, seed: String) throws -> String {
        let plaintext = Data(text.utf8)
        let sealed: AES.GCM.SealedBox
        do { sealed = try AES.GCM.seal(plaintext, using: symmetricKey(from: seed)) }
        catch { throw MorseCipherError.encryptionFailed }
        guard let combined = sealed.combined else { throw MorseCipherError.encryptionFailed }
        return hexString(from: combined)
    }

    static func decrypt(_ hex: String, seed: String) throws -> String {
        guard let data = data(fromHex: hex) else { throw MorseCipherError.invalidHexInput }
        do {
            let box = try AES.GCM.SealedBox(combined: data)
            let plain = try AES.GCM.open(box, using: symmetricKey(from: seed))
            return String(data: plain, encoding: .utf8) ?? ""
        } catch let e as MorseCipherError {
            throw e
        } catch {
            throw MorseCipherError.decryptionFailed(error.localizedDescription)
        }
    }

    // MARK: Internal helpers (exposed for testing)

    static func symmetricKey(from seed: String) -> SymmetricKey {
        SymmetricKey(data: SHA256.hash(data: Data(seed.utf8)))
    }

    static func hexString(from data: Data) -> String {
        data.map { String(format: "%02X", $0) }.joined()
    }

    static func data(fromHex hex: String) -> Data? {
        let s = hex.uppercased()
        guard s.count % 2 == 0 else { return nil }
        var out = Data(capacity: s.count / 2)
        var idx = s.startIndex
        while idx < s.endIndex {
            let next = s.index(idx, offsetBy: 2)
            guard let byte = UInt8(s[idx..<next], radix: 16) else { return nil }
            out.append(byte)
            idx = next
        }
        return out
    }
}
