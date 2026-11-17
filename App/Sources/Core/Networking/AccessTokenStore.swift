import Foundation
import Security

protocol AccessTokenStoring: Sendable {
    var token: String? { get }
    func save(_ token: String)
    func clear()
}

final class AccessTokenStore: AccessTokenStoring, @unchecked Sendable {
    static let shared = AccessTokenStore()

    private let service: String
    private let account = "accessToken"
    private let lock = NSLock()
    private var sessionOnlyToken: String?

    init(service: String = "kr.hs.gsm.hopes.auth") {
        self.service = service
    }

    var isSessionOnly: Bool {
        lock.lock()
        defer { lock.unlock() }
        return sessionOnlyToken != nil
    }

    var token: String? {
        lock.lock()
        defer { lock.unlock() }
        if let sessionOnlyToken { return sessionOnlyToken }
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
        save(token, persistent: true)
    }

    func save(_ token: String, persistent: Bool) {
        lock.lock()
        defer { lock.unlock() }
        SecItemDelete(baseQuery as CFDictionary)
        guard persistent else {
            sessionOnlyToken = token
            return
        }
        sessionOnlyToken = nil
        var query = baseQuery
        query[kSecValueData as String] = Data(token.utf8)
        query[kSecAttrAccessible as String] = kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly
        SecItemAdd(query as CFDictionary, nil)
    }

    func clear() {
        lock.lock()
        defer { lock.unlock() }
        sessionOnlyToken = nil
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
