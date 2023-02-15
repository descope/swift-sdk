
import Foundation

/// A `DescopeSession` is returned as a result of a successful sign in operation.
public class DescopeSession {
    
    /// The underlying value for the short lived JWT that is sent with every
    /// request that requires authentication.
    private var sessionToken: Token
    
    /// The underlying value for the longer lived JWT that is used to create
    /// new session JWTs until it expires.
    private var refreshToken: Token
    
    /// Creates a new `DescopeSession` instance from two JWT strings.
    ///
    /// Use this constructor to recreate a user's session after an
    /// application is relaunched.
    public convenience init(sessionJwt: String, refreshJwt: String) throws {
        let sessionToken = try Token(jwt: sessionJwt)
        let refreshToken = try Token(jwt: refreshJwt)
        self.init(sessionToken: sessionToken, refreshToken: refreshToken)
    }
    
    init(sessionToken: Token, refreshToken: Token) {
        self.sessionToken = sessionToken
        self.refreshToken = refreshToken
    }
    
    /// The short lived JWT that is sent with every request that
    /// requires authentication.
    public var sessionJwt: String { sessionToken.jwt }
    
    /// The longer lived JWT that is used to create new session JWTs
    /// until it expires.
    public var refreshJwt: String { refreshToken.jwt }
    
    /// The unique id of the user this session was created for.
    public var userId: String { refreshToken.id }
    
    /// The unique id of the Descope project this session was created for.
    public var projectId: String { refreshToken.projectId }
    
    /// The time after which the refresh JWT expires, if any.
    public var expiresAt: Date? { refreshToken.expiresAt }
    
    /// Whether the refresh JWT expiry time (if any) has already passed.
    public var isExpired: Bool { refreshToken.isExpired }

    /// A map with all the custom claims in the underlying JWT. It includes
    /// any claims whose values aren't already exposed by other accessors or
    /// authorization functions.
    public var claims: [String: Any] { refreshToken.claims }
    
    /// Returns the list of permissions granted for the user.
    /// Pass `nil` for the `tenant` parameter if the user isn't
    /// associated with any tenant.
    public func permissions(tenant: String?) -> [String] {
        refreshToken.permissions(tenant: tenant)
    }
    
    /// Returns the list of roles for the user. Pass `nil` for
    /// the `tenant` parameter if the user isn't associated with
    /// any tenant.
    public func roles(tenant: String?) -> [String] {
        refreshToken.roles(tenant: tenant)
    }
}

extension DescopeSession: CustomStringConvertible {
    /// Returns a textual representation of this `DescopeSession`.
    public var description: String {
        var expires = "expires: Never"
        if let expiresAt {
            let label = expiresAt.timeIntervalSinceNow > 0 ? "expires" : "expired"
            expires = "\(label): \(expiresAt)"
        }
        return "DescopeSession(id: \"\(userId)\", \(expires))"
    }
}
