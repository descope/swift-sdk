
import Foundation

public class DescopeSessionManager {
    public let storage: DescopeSessionStorage
    public let lifecycle: DescopeSessionLifecycle
    
    public init(storage: DescopeSessionStorage, lifecycle: DescopeSessionLifecycle) {
        self.storage = storage
        self.lifecycle = lifecycle
        self.session = storage.loadSession()
        self.lifecycle.session = session
    }
    
    public var session: DescopeSession? {
        didSet {
            guard session !== oldValue else { return }
            lifecycle.session = session
            if let session {
                storage.saveSession(session)
            } else {
                storage.removeSession()
            }
        }
    }
    
    public func refreshSessionIfNeeded() async throws {
        guard let session else { return }
        let value = session.sessionJwt
        try await lifecycle.refreshSessionIfNeeded()
        if value != session.sessionJwt {
            storage.saveSession(session)
        }
    }
    
    public func updateSession(with refreshResponse: RefreshResponse) {
        guard let session else { return }
        session.update(with: refreshResponse)
        storage.saveSession(session)
    }
    
    public func updateSession(with user: DescopeUser) {
        guard let session else { return }
        session.update(with: user)
        storage.saveSession(session)
    }
}
