
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
