
import Foundation

class MagicLink: DescopeMagicLink {
    let client: DescopeClient
    
    init(client: DescopeClient) {
        self.client = client
    }
    
    func signUp(with method: DeliveryMethod, loginId: String, user: User, uri: String?) async throws {
        try await client.magicLinkSignUp(with: method, loginId: loginId, user: user, uri: uri)
    }
    
    func signIn(with method: DeliveryMethod, loginId: String, uri: String?) async throws {
        try await client.magicLinkSignIn(with: method, loginId: loginId, uri: uri)
    }
    
    func signUpOrIn(with method: DeliveryMethod, loginId: String, uri: String?) async throws {
        try await client.magicLinkSignUpOrIn(with: method, loginId: loginId, uri: uri)
    }
    
    func updateEmail(_ email: String, loginId: String, refreshJwt: String) async throws {
        try await client.magicLinkUpdateEmail(email, loginId: loginId, refreshJwt: refreshJwt)
    }
    
    func updatePhone(_ phone: String, with method: DeliveryMethod, loginId: String, refreshJwt: String) async throws {
        try await client.magicLinkUpdatePhone(phone, with: method, loginId: loginId, refreshJwt: refreshJwt)
    }
    
    func verify(token: String) async throws -> DescopeSession {
        return try await client.magicLinkVerify(token: token).convert()
    }
}
