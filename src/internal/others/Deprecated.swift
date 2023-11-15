
import Foundation

public extension DescopeOTP {
    @available(*, deprecated, message: "Pass a value (or an empty array) for the options parameter")
    func signIn(with method: DeliveryMethod, loginId: String) async throws -> String {
        return try await signIn(with: method, loginId: loginId, options: [])
    }
    
    @available(*, deprecated, message: "Pass a value (or an empty array) for the options parameter")
    func signUpOrIn(with method: DeliveryMethod, loginId: String) async throws -> String {
        return try await signUpOrIn(with: method, loginId: loginId, options: [])
    }
}

public extension DescopeTOTP {
    @available(*, deprecated, message: "Pass a value (or an empty array) for the options parameter")
    func verify(loginId: String, code: String) async throws -> AuthenticationResponse {
        return try await verify(loginId: loginId, code: code, options: [])
    }
}

public extension DescopeMagicLink {
    @available(*, deprecated, message: "Pass a value (or an empty array) for the options parameter")
    func signIn(with method: DeliveryMethod, loginId: String, redirectURL: String?) async throws -> String {
        return try await signIn(with: method, loginId: loginId, redirectURL: redirectURL, options: [])
    }
    
    @available(*, deprecated, message: "Pass a value (or an empty array) for the options parameter")
    func signUpOrIn(with method: DeliveryMethod, loginId: String, redirectURL: String?) async throws -> String {
        return try await signUpOrIn(with: method, loginId: loginId, redirectURL: redirectURL, options: [])
    }
}

public extension DescopeEnchantedLink {
    @available(*, deprecated, message: "Pass a value (or an empty array) for the options parameter")
    func signIn(loginId: String, redirectURL: String?) async throws -> EnchantedLinkResponse {
        return try await signIn(loginId: loginId, redirectURL: redirectURL, options: [])
    }
    
    @available(*, deprecated, message: "Pass a value (or an empty array) for the options parameter")
    func signUpOrIn(loginId: String, redirectURL: String?) async throws -> EnchantedLinkResponse {
        return try await signUpOrIn(loginId: loginId, redirectURL: redirectURL, options: [])
    }
}

public extension DescopeOAuth {
    @available(*, deprecated, message: "Pass a value (or an empty array) for the options parameter")
    func start(provider: OAuthProvider, redirectURL: String?) async throws -> String {
        return try await start(provider: provider, redirectURL: redirectURL, options: [])
    }
}

public extension DescopeSSO {
    @available(*, deprecated, message: "Pass a value (or an empty array) for the options parameter")
    func start(emailOrTenantName: String, redirectURL: String?) async throws -> String {
        return try await start(emailOrTenantName: emailOrTenantName, redirectURL: redirectURL, options: [])
    }
}

public extension URLRequest {
    @available(*, deprecated, message: "Use setAuthorization instead")
    mutating func setAuthorizationHTTPHeaderField(from sessionManager: DescopeSessionManager) async throws {
        try await setAuthorization(from: sessionManager, config: DescopeConfig)
    }
    
    @available(*, unavailable, message: "Use setAuthorization instead")
    mutating func setAuthorizationHTTPHeaderField(from session: DescopeSession) {
    }

    @available(*, unavailable, message: "Use setAuthorization instead")
    mutating func setAuthorizationHTTPHeaderField(from token: DescopeToken) {
    }
}
