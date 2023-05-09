
import Foundation

/// This protocol can be used to customize how a `DescopeSessionManager` object
/// stores the active `DescopeSession` between application launches.
public protocol DescopeSessionStorage: AnyObject {
    /// Called by the session manager when a new session was set or an
    /// existing session was updated.
    func saveSession(_ session: DescopeSession)
    
    /// Called by the session manager when it's initialized to load any
    /// existing session.
    func loadSession() -> DescopeSession?
    
    /// Called by the session manager when its session is set to `nil`.
    func removeSession()
}

/// The default implementation of the `DescopeSessionStorage` protocol.
///
/// The `SessionStorage` class ensures that the `DescopeSession` is kept in
/// a secure manner in the devices's keychain. On iOS the keychain guarantees
/// that the tokens are encrypted at rest with an encryption key that only
/// becomes available to the operating system after the device is unlocked
/// at least once after it's powered on.
///
/// For your convenience, you can subclass `SessionStorage` and override
/// the `loadItem`, `saveItem` and `removeItem` functions to create a similar
/// implementation that just uses a different backing store.
open class SessionStorage: DescopeSessionStorage {
    
    public let key: String
    
    private var lastValue: StorageHelper?
    
    public init(key: String) {
        self.key = key
    }
    
    public func saveSession(_ session: DescopeSession) {
        let value = StorageHelper(sessionJwt: session.sessionJwt, refreshJwt: session.refreshJwt, user: session.user)
        guard value != lastValue else { return }
        guard let data = try? JSONEncoder().encode(value) else { return }
        saveItem(data: data)
        lastValue = value
    }
    
    public func loadSession() -> DescopeSession? {
        guard let data = loadItem() else { return nil }
        guard let value = try? JSONDecoder().decode(StorageHelper.self, from: data) else { return nil }
        return try? DescopeSession(sessionJwt: value.sessionJwt, refreshJwt: value.refreshJwt, user: value.user)
    }
    
    public func removeSession() {
        removeItem()
    }
    
    open func loadItem() -> Data? {
        var attrs = attributesForItem(key: key)
        attrs[kSecReturnData as String] = true
        attrs[kSecMatchLimit as String] = kSecMatchLimitOne
        
        var value: AnyObject?
        SecItemCopyMatching(attrs as CFDictionary, &value)
        return value as? Data
    }
    
    open func saveItem(data: Data) {
        let attrs = attributesForItem(key: key)
        
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
    
    open func removeItem() {
        let attrs = attributesForItem(key: key)
        SecItemDelete(attrs as CFDictionary)
    }
}

private func attributesForItem(key: String) -> [String: Any] {
    return [
        kSecClass as String: kSecClassGenericPassword,
        kSecAttrService as String: "com.descope.DescopeKit",
        kSecAttrAccount as String: key,
    ]
}

/// A helper struct for serializing the `DescopeSession` data.
private struct StorageHelper: Codable, Equatable {
    var sessionJwt: String
    var refreshJwt: String
    var user: DescopeUser
}
