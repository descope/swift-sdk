
import Foundation

class MagicLink: DescopeMagicLink {
    let client: DescopeClient
    
    init(client: DescopeClient) {
        self.client = client
    }
    
    func signUp(with method: DeliveryMethod, loginId: String, user: User, uri: String?) async throws -> String {
        return try await client.magicLinkSignUp(with: method, loginId: loginId, user: user, uri: uri).convert(method: method)
    }
    
    func signIn(with method: DeliveryMethod, loginId: String, uri: String?) async throws -> String {
        return try await client.magicLinkSignIn(with: method, loginId: loginId, uri: uri).convert(method: method)
    }
    
    func signUpOrIn(with method: DeliveryMethod, loginId: String, uri: String?) async throws -> String {
        return try await client.magicLinkSignUpOrIn(with: method, loginId: loginId, uri: uri).convert(method: method)
    }
    
    func updateEmail(_ email: String, loginId: String, uri: String?, refreshJwt: String, options: UpdateOptions) async throws -> String {
        return try await client.magicLinkUpdateEmail(email, loginId: loginId, uri: uri, refreshJwt: refreshJwt, options: options).convert(method: .email)
    }
    
    func updatePhone(_ phone: String, with method: DeliveryMethod, loginId: String, uri: String?, refreshJwt: String, options: UpdateOptions) async throws -> String {
        return try await client.magicLinkUpdatePhone(phone, with: method, loginId: loginId, uri: uri, refreshJwt: refreshJwt, options: options).convert(method: method)
    }
    
    func verify(token: String) async throws -> DescopeSession {
        return try await client.magicLinkVerify(token: token).convert()
    }
}
