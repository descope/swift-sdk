
import Foundation

public protocol DescopeAuth {
    var accessKey: DescopeAccessKey { get }
    var otp: DescopeOTP { get }
    var totp: DescopeTOTP { get }
    var magicLink: DescopeMagicLink { get }
    
    func me(token: String) async throws -> MeResponse
}

public protocol DescopeAccessKey {
    func exchange(accessKey: String) async throws -> Token
}

public protocol DescopeOTP {
    func signUp(with method: DeliveryMethod, identifier: String, user: User) async throws
    func signIn(with method: DeliveryMethod, identifier: String) async throws
    func signUpOrIn(with method: DeliveryMethod, identifier: String) async throws
    func verify(with method: DeliveryMethod, identifier: String, code: String) async throws -> [Token]
    func updateEmail(_ email: String, identifier: String, refreshToken: String) async throws
    func updatePhone(_ phone: String, with method: DeliveryMethod, identifier: String, refreshToken: String) async throws
}

public protocol DescopeTOTP {
    func signUp(identifier: String, user: User) async throws -> TOTPResponse
    func update(identifier: String, refreshToken: String) async throws
    func verify(identifier: String, code: String) async throws -> [Token]
}

public protocol DescopeMagicLink {
    func signUp(with method: DeliveryMethod, identifier: String, user: User, uri: String?) async throws
    func signIn(with method: DeliveryMethod, identifier: String, uri: String?) async throws
    func signUpOrIn(with method: DeliveryMethod, identifier: String, uri: String?) async throws
    func updateEmail(_ email: String, identifier: String, refreshToken: String) async throws
    func updatePhone(_ phone: String, with method: DeliveryMethod, identifier: String, refreshToken: String) async throws
    func verify(token: String) async throws -> [Token]
    func signUpCrossDevice(with method: DeliveryMethod, identifier: String, user: User, uri: String?) async throws -> [Token]
    func signInCrossDevice(with method: DeliveryMethod, identifier: String, uri: String?) async throws -> [Token]
    func signUpOrInCrossDevice(with method: DeliveryMethod, identifier: String, uri: String?) async throws -> [Token]
}
