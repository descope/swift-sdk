
import Foundation

/// The `DescopeSession` class represents a successful sign in operation.
public class DescopeSession {
    /// The wrapper for the short lived JWT that can be sent with every server
    /// request that requires authentication.
    public private(set) var sessionToken: DescopeToken
    
    /// The wrapper for the longer lived JWT that is used to create
    /// new session JWTs until it expires.
    public private(set) var refreshToken: DescopeToken
    
    /// The details about the user to whom the `DescopeSession` belongs to.
    public private(set) var user: DescopeUser
    
    /// Creates a new `DescopeSession` object from an `AuthenticationResponse`.
    ///
    /// Use this constructor to create a `DescopeSession` after the user completes
    /// a sign in or sign up flow in the application.
    public convenience init(from response: AuthenticationResponse) {
        self.init(sessionToken: response.sessionToken, refreshToken: response.refreshToken, user: response.user)
    }
    
    /// Creates a new `DescopeSession` object from two JWT strings.
    ///
    /// This constructor can be used to recreate a user's `DescopeSession` after
    /// the application is relaunched.
    public convenience init(sessionJwt: String, refreshJwt: String, user: DescopeUser) throws {
        let sessionToken = try Token(jwt: sessionJwt)
        let refreshToken = try Token(jwt: refreshJwt)
        self.init(sessionToken: sessionToken, refreshToken: refreshToken, user: user)
    }
    
    /// Creates a new `DescopeSession` object.
    public init(sessionToken: DescopeToken, refreshToken: DescopeToken, user: DescopeUser) {
        self.sessionToken = sessionToken
        self.refreshToken = refreshToken
        self.user = user
    }
}

// State

public extension DescopeSession {
    /// The possible states for a `DescopeSession` object.
    enum State {
        /// The `DescopeSession` has valid session and refresh JWTs and can be used
        /// to authenticate outgoing server requests.
        case valid
        
        /// The session JWT is no longer valid but the refresh JWT can be used to
        /// get a new one.
        case sessionExpired
        
        /// The refresh JWT is no longer valid and the application should most likely
        /// ask the user to sign in again.
        case refreshExpired
    }
    
    /// The current state of this `DescopeSession` object.
    var state: State {
        if refreshToken.isExpired {
            return .refreshExpired
        }
        if sessionToken.isExpired {
            return .sessionExpired
        }
        return .valid
    }
}

// Accessors

public extension DescopeSession {
    /// The short lived JWT that is sent with every request that
    /// requires authentication.
    var sessionJwt: String { sessionToken.jwt }
    
    /// The longer lived JWT that is used to create new session JWTs
    /// until it expires.
    var refreshJwt: String { refreshToken.jwt }
    
    /// A map with all the custom claims in the underlying JWT. It includes
    /// any claims whose values aren't already exposed by other accessors or
    /// authorization functions.
    var claims: [String: Any] { refreshToken.claims }

    /// Returns the list of permissions granted for the user. Pass `nil` for
    /// the `tenant` parameter if the user isn't associated with any tenant.
    func permissions(tenant: String?) -> [String] { refreshToken.permissions(tenant: tenant) }
    
    /// Returns the list of roles for the user. Pass `nil` for the `tenant`
    /// parameter if the user isn't associated with any tenant.
    func roles(tenant: String?) -> [String] { refreshToken.roles(tenant: tenant) }
}

// Refresh

public extension DescopeSession {
    func update(with refreshResponse: RefreshResponse) {
        sessionToken = refreshResponse.sessionToken
        refreshToken = refreshResponse.refreshToken ?? refreshToken
    }
    
    func update(with user: DescopeUser) {
        self.user = user
    }
}

// Description

extension DescopeSession: CustomStringConvertible {
    /// Returns a textual representation of this `DescopeSession`.
    public var description: String {
        var expires = "expires: Never"
        if let refreshExpiresAt = refreshToken.expiresAt {
            let label = refreshToken.isExpired ? "expired" : "expires"
            expires = "\(label): \(refreshExpiresAt)"
        }
        return "DescopeSession(id: \"\(user.userId)\", \(expires))"
    }
}
