
public protocol DescopeAuth {
    func me(refreshJwt: String) async throws -> MeResponse
    func refreshSession(refreshJwt: String) async throws -> DescopeSession
    func logout(refreshJwt: String) async throws
}

public protocol DescopeAccessKey {
    func exchange(accessKey: String) async throws -> DescopeToken
}

public protocol DescopeOTP {
    func signUp(with method: DeliveryMethod, loginId: String, user: User) async throws
    func signIn(with method: DeliveryMethod, loginId: String) async throws
    func signUpOrIn(with method: DeliveryMethod, loginId: String) async throws
    func verify(with method: DeliveryMethod, loginId: String, code: String) async throws -> DescopeSession
    func updateEmail(_ email: String, loginId: String, refreshJwt: String) async throws
    func updatePhone(_ phone: String, with method: DeliveryMethod, loginId: String, refreshJwt: String) async throws
}

public protocol DescopeTOTP {
    func signUp(loginId: String, user: User) async throws -> TOTPResponse
    func update(loginId: String, refreshJwt: String) async throws -> TOTPResponse
    func verify(loginId: String, code: String) async throws -> DescopeSession
}

public protocol DescopeMagicLink {
    func signUp(with method: DeliveryMethod, loginId: String, user: User, uri: String?) async throws
    func signIn(with method: DeliveryMethod, loginId: String, uri: String?) async throws
    func signUpOrIn(with method: DeliveryMethod, loginId: String, uri: String?) async throws
    func updateEmail(_ email: String, loginId: String, refreshJwt: String) async throws
    func updatePhone(_ phone: String, with method: DeliveryMethod, loginId: String, refreshJwt: String) async throws
    func verify(token: String) async throws -> DescopeSession
}

public protocol DescopeEnchantedLink {
    func signUp(loginId: String, user: User, uri: String?) async throws -> EnchantedLinkResponse
    func signIn(loginId: String, uri: String?) async throws -> EnchantedLinkResponse
    func signUpOrIn(loginId: String, uri: String?) async throws -> EnchantedLinkResponse
    func verify(token: String, pendingRef: String) async throws -> DescopeSession
    func updateEmail(email: String, loginId: String, uri: String?, refreshJwt: String) async throws -> EnchantedLinkResponse
}

public protocol DescopeOAuth {
    func start(provider: OAuthProvider, redirectURL: String?) async throws -> String
    func exchange(code: String) async throws -> DescopeSession
}

public protocol DescopeSSO {
    func start(emailOrTenantName: String, redirectURL: String?) async throws -> String
    func exchange(code: String) async throws -> DescopeSession
}
