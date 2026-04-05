import Foundation
import Security

struct EVCredential {
    let email: String
    let password: String
}

enum EVCredentialStore {
    private static let service = "com.edventure.auth"
    private static let account = "biometric-login"

    static func save(email: String, password: String) -> Bool {
        guard let data = "\(email)\n\(password)".data(using: .utf8) else { return false }

        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account
        ]

        SecItemDelete(query as CFDictionary)

        var addQuery = query
        addQuery[kSecValueData as String] = data
        addQuery[kSecAttrAccessible as String] = kSecAttrAccessibleWhenUnlockedThisDeviceOnly

        return SecItemAdd(addQuery as CFDictionary, nil) == errSecSuccess
    }

    static func load() -> EVCredential? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]

        var item: CFTypeRef?
        guard SecItemCopyMatching(query as CFDictionary, &item) == errSecSuccess,
              let data = item as? Data,
              let raw = String(data: data, encoding: .utf8)
        else {
            return nil
        }

        let parts = raw.components(separatedBy: "\n")
        guard parts.count >= 2 else { return nil }
        return EVCredential(email: parts[0], password: parts[1])
    }

    static func clear() {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account
        ]

        SecItemDelete(query as CFDictionary)
    }
}
