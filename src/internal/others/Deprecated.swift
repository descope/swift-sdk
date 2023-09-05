
import Foundation

/// See the documentation for `DescopeUser`.
@available(*, unavailable, renamed: "DescopeUser")
public typealias MeResponse = DescopeUser

/// See the documentation for `SignUpDetails`.
@available(*, unavailable, renamed: "SignUpDetails")
public typealias User = SignUpDetails

/// See the documentation for `PasswordPolicyResponse`.
@available(*, unavailable, renamed: "PasswordPolicyResponse")
public typealias PasswordPolicy = PasswordPolicyResponse

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
