
import Foundation

public protocol DescopeSession {
    var jwt: String { get }
    var refreshJwt: String { get }
    
    var id: String { get }
    var projectId: String { get }
    
    var expiresAt: Date? { get }
    var isExpired: Bool { get }
    
    var claims: [String: Any] { get }
    
    func permissions(forTenant tenant: String?) -> [String]
    func roles(forTenant tenant: String?) -> [String]
}

extension URLRequest {
    mutating func addAuthorizationHeaderValue(session: DescopeSession) {
        addValue("Bearer \(session.projectId):\(session.jwt)", forHTTPHeaderField: "Authorization")
    }
}

// Implementation

class Session: DescopeSession {
    let sessionToken: DescopeToken
    let refreshToken: DescopeToken
    
    init(sessionToken: DescopeToken, refreshToken: DescopeToken) {
        self.sessionToken = sessionToken
        self.refreshToken = refreshToken
    }
    
    var jwt: String { sessionToken.jwt }
    var refreshJwt: String { refreshToken.jwt }
    
    var id: String { sessionToken.id }
    var projectId: String { sessionToken.projectId }
    
    var expiresAt: Date? { refreshToken.expiresAt }
    var isExpired: Bool { refreshToken.isExpired }

    var claims: [String: Any] { sessionToken.claims }
    
    func permissions(forTenant tenant: String?) -> [String] { sessionToken.permissions(forTenant: tenant) }
    func roles(forTenant tenant: String?) -> [String] { sessionToken.roles(forTenant: tenant) }
}

// Description

extension Session: CustomStringConvertible {
    var description: String {
        var expires = "expires: Never"
        if let expiresAt {
            let label = expiresAt.timeIntervalSinceNow > 0 ? "expires" : "expired"
            expires = "\(label): \(expiresAt)"
        }
        return "DescopeSession(id: \"\(id)\", project: \"\(projectId)\", \(expires))"
    }
}
