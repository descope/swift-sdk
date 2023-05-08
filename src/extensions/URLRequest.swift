
import Foundation

public extension URLRequest {
    mutating func addAuthorizationHTTPHeaderField(from sessionManager: DescopeSessionManager) async throws {
        guard let session = sessionManager.session else { return }
        try await sessionManager.refreshSessionIfNeeded()
        addAuthorizationHTTPHeaderField(from: session)
    }
    
    mutating func addAuthorizationHTTPHeaderField(from session: DescopeSession) {
        addAuthorizationHTTPHeaderField(from: session.sessionToken)
    }

    mutating func addAuthorizationHTTPHeaderField(from token: DescopeToken) {
        addValue("Bearer \(token.jwt)", forHTTPHeaderField: "Authorization")
    }
}
