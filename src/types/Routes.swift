
public protocol DescopeAuth {
    func me(refreshToken: String) async throws -> MeResponse
}

public protocol DescopeAccessKey {
    func exchange(accessKey: String) async throws -> DescopeSession
}

public protocol DescopeOTP {
    func signUp(with method: DeliveryMethod, identifier: String, user: User) async throws
    func signIn(with method: DeliveryMethod, identifier: String) async throws
    func signUpOrIn(with method: DeliveryMethod, identifier: String) async throws
    func verify(with method: DeliveryMethod, identifier: String, code: String) async throws -> DescopeSession
    func updateEmail(_ email: String, identifier: String, refreshToken: String) async throws
    func updatePhone(_ phone: String, with method: DeliveryMethod, identifier: String, refreshToken: String) async throws
}

public protocol DescopeTOTP {
    func signUp(identifier: String, user: User) async throws -> TOTPResponse
    func update(identifier: String, refreshToken: String) async throws
    func verify(identifier: String, code: String) async throws -> DescopeSession
}

public protocol DescopeMagicLink {
    func signUp(with method: DeliveryMethod, identifier: String, user: User, uri: String?) async throws
    func signIn(with method: DeliveryMethod, identifier: String, uri: String?) async throws
    func signUpOrIn(with method: DeliveryMethod, identifier: String, uri: String?) async throws
    func updateEmail(_ email: String, identifier: String, refreshToken: String) async throws
    func updatePhone(_ phone: String, with method: DeliveryMethod, identifier: String, refreshToken: String) async throws
    func verify(token: String) async throws -> DescopeSession
    func signUpCrossDevice(with method: DeliveryMethod, identifier: String, user: User, uri: String?) async throws -> DescopeSession
    func signInCrossDevice(with method: DeliveryMethod, identifier: String, uri: String?) async throws -> DescopeSession
    func signUpOrInCrossDevice(with method: DeliveryMethod, identifier: String, uri: String?) async throws -> DescopeSession
}

public protocol DescopeOAuth {
    func start(provider: OAuthProvider, redirectURL: String?) async throws -> String
    func exchange(code: String) async throws -> DescopeSession
}

public protocol DescopeSSO {
    func start(emailOrTenantName: String, redirectURL: String?) async throws -> String
    func exchange(code: String) async throws -> DescopeSession
}
