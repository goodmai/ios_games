import Foundation
import Security

/// Keychain-backed implementation of PINStorage.
/// Each entry is a generic password item keyed by `service + account`.
struct KeychainStore: PINStorage {

    private let service: String

    init(service: String = Bundle.main.bundleIdentifier ?? "com.goodmai.MorseLight") {
        self.service = service
    }

    @discardableResult
    func set(_ data: Data, forKey key: String) -> Bool {
        var query = baseQuery(for: key)
        query[kSecValueData as String] = data
        SecItemDelete(query as CFDictionary)            // delete existing before add
        return SecItemAdd(query as CFDictionary, nil) == errSecSuccess
    }

    func data(forKey key: String) -> Data? {
        var query = baseQuery(for: key)
        query[kSecReturnData  as String] = true
        query[kSecMatchLimit  as String] = kSecMatchLimitOne
        var ref: AnyObject?
        guard SecItemCopyMatching(query as CFDictionary, &ref) == errSecSuccess else { return nil }
        return ref as? Data
    }

    func deleteAll() {
        let query: [String: Any] = [
            kSecClass       as String: kSecClassGenericPassword,
            kSecAttrService as String: service
        ]
        SecItemDelete(query as CFDictionary)
    }

    private func baseQuery(for key: String) -> [String: Any] {
        [
            kSecClass       as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key
        ]
    }
}
