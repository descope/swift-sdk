
import Foundation

public protocol DescopeSessionStorage: AnyObject {
    func saveSession(_ session: DescopeSession)
    func loadSession() -> DescopeSession?
    func removeSession()
}

/// The default implementation of the `DescopeSessionStorage` protocol.
///
/// The `SessionStorage` class ensures that the `DescopeSession` is kept in a secure
/// manner in the devices's keychain. On iOS the keychain guarantees that the tokens
/// are encrypted at rest with a key that only becomes available to the OS after the
/// device is unlocked once after reboot.
public class SessionStorage: DescopeSessionStorage {
    public func saveSession(_ session: DescopeSession) {
        let value = KeychainSession(sessionJwt: session.sessionJwt, refreshJwt: session.refreshJwt, user: session.user)
        guard let data = try? JSONEncoder().encode(value) else { return }
        saveItem(named: "session", data: data)
    }
    
    public func loadSession() -> DescopeSession? {
        guard let data = loadItem(named: "session") else { return nil }
        guard let value = try? JSONDecoder().decode(KeychainSession.self, from: data) else { return nil }
        return try? DescopeSession(sessionJwt: value.sessionJwt, refreshJwt: value.refreshJwt, user: value.user)
    }
    
    public func removeSession() {
        removeItem(named: "session")
    }
    
    // Keychain
    
    private func loadItem(named name: String) -> Data? {
        var attrs = attributesForItem(named: name)
        attrs[kSecReturnData as String] = true
        attrs[kSecMatchLimit as String] = kSecMatchLimitOne
        
        var value: AnyObject?
        SecItemCopyMatching(attrs as CFDictionary, &value)
        return value as? Data
    }
    
    private func saveItem(named name: String, data: Data) {
        let attrs = attributesForItem(named: name)
        
        let values: [String: Any] = [
            kSecValueData as String: data,
            kSecAttrAccess as String: kSecAttrAccessibleAfterFirstUnlock,
        ]
        
        let result = SecItemCopyMatching(attrs as CFDictionary, nil)
        if result == errSecSuccess {
            SecItemUpdate(attrs as CFDictionary, values as CFDictionary)
        } else if result == errSecItemNotFound {
            let merged = attrs.merging(values, uniquingKeysWith: { $1 })
            SecItemAdd(merged as CFDictionary, nil)
        }
    }
    
    private func removeItem(named name: String) {
        let attrs = attributesForItem(named: name)
        SecItemDelete(attrs as CFDictionary)
    }

    private func attributesForItem(named name: String) -> [String: Any] {
        return [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: "com.descope.DescopeKit",
            kSecAttrAccount as String: name,
        ]
    }
}

/// A helper struct for serializing the `DescopeSession` data.
private struct KeychainSession: Codable {
    var sessionJwt: String
    var refreshJwt: String
    var user: DescopeUser
}