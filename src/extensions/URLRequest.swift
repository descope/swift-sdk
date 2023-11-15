
import Foundation

public extension URLRequest {
    ///
    mutating func setAuthorization(from sessionManager: DescopeSessionManager, config: DescopeConfig = .init(projectId: "")) async throws {
        guard let session = sessionManager.session else { return }
        try await sessionManager.refreshSessionIfNeeded()
        
        switch config.authorization {
        case .bearerToken:
            setValue("Bearer \(session.sessionJwt)", forHTTPHeaderField: "Authorization")
        case .httpHeader(let handler):
            let (name, value) = handler(session.sessionToken)
            setValue(value, forHTTPHeaderField: name)
        case .custom(let handler):
            handler(session.sessionToken, &self)
        }
    }
}
