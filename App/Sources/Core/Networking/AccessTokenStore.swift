import Foundation
import Security

final class AccessTokenStore: @unchecked Sendable {
    static let shared = AccessTokenStore()

    private let service = "kr.hs.gsm.hopes.auth"
    private let account = "accessToken"
    private let lock = NSLock()

    var token: String? {
        lock.lock()
        defer { lock.unlock() }
        var query = baseQuery
        query[kSecReturnData as String] = true
        query[kSecMatchLimit as String] = kSecMatchLimitOne
        var item: CFTypeRef?
        guard SecItemCopyMatching(query as CFDictionary, &item) == errSecSuccess,
              let data = item as? Data else { return nil }
        return String(data: data, encoding: .utf8)
    }

    var hasToken: Bool { token != nil }

    func save(_ token: String) {
        lock.lock()
        defer { lock.unlock() }
        SecItemDelete(baseQuery as CFDictionary)
        var query = baseQuery
        query[kSecValueData as String] = Data(token.utf8)
        query[kSecAttrAccessible as String] = kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly
        SecItemAdd(query as CFDictionary, nil)
    }

    func clear() {
        lock.lock()
        defer { lock.unlock() }
        SecItemDelete(baseQuery as CFDictionary)
    }

    private var baseQuery: [String: Any] {
        [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account
        ]
    }
}
