
import Foundation

// TODO should this conform to DescopeToken? or just duplicate?
public protocol DescopeSession: DescopeToken {
    // TODO do we need the above? or the below? or both?
    var sessionToken: DescopeToken { get }
    var refreshToken: DescopeToken? { get }
    
    var refreshJWT: String? { get }
}

// Implementation

class Session: DescopeSession {
    let sessionToken: DescopeToken
    let refreshToken: DescopeToken?
    
    init(sessionToken: DescopeToken, refreshToken: DescopeToken?) {
        self.sessionToken = sessionToken
        self.refreshToken = refreshToken
    }
    
    var jwt: String { sessionToken.jwt }
    var refreshJWT: String? { refreshToken?.jwt }
    var id: String { sessionToken.id }
    var projectId: String { sessionToken.projectId }
    var claims: [String: Any] { sessionToken.claims }

    var expiresAt: Date? { refreshToken?.expiresAt ?? sessionToken.expiresAt }
    var isExpired: Bool { refreshToken?.isExpired ?? sessionToken.isExpired }

    func permissions(forTenant tenant: String?) -> [String] { sessionToken.permissions(forTenant: tenant) }
    func roles(forTenant tenant: String?) -> [String] { sessionToken.roles(forTenant: tenant) }
}

// Description

extension Session: CustomStringConvertible {
    var description: String {
        var expires = "expires: Never"
        if let expiresAt {
            let tag = expiresAt.timeIntervalSinceNow > 0 ? "expires" : "expired"
            expires = "\(tag): \(expiresAt)"
        }
        return "DescopeSession(id: \"\(id)\", project: \"\(projectId)\", \(expires))"
    }
}
