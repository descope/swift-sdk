
import Foundation
import Combine

class MagicLink: DescopeMagicLink {
    let client: DescopeClient
    
    init(client: DescopeClient) {
        self.client = client
    }
    
    // MARK: - Same-Device
    
    func signUp(with method: DeliveryMethod, identifier: String, user: User, uri: String?) async throws {
        try await callSignUp(with: method, identifier: identifier, user: user, uri: uri)
    }
    
    func signIn(with method: DeliveryMethod, identifier: String, uri: String?) async throws {
        try await callSignIn(with: method, identifier: identifier, uri: uri)
    }
    
    func signUpOrIn(with method: DeliveryMethod, identifier: String, uri: String?) async throws {
        try await callSignUpOrIn(with: method, identifier: identifier, uri: uri)
    }
    
    func updateEmail(_ email: String, identifier: String, refreshToken: String) async throws {
        try await client.magicLinkUpdateEmail(email, identifier: identifier, refreshToken: refreshToken)
    }
    
    func updatePhone(_ phone: String, with method: DeliveryMethod, identifier: String, refreshToken: String) async throws {
        try await client.magicLinkUpdatePhone(phone, with: method, identifier: identifier, refreshToken: refreshToken)
    }
    
    func verify(token: String) async throws -> [Token] {
        let response = try await client.magicLinkVerify(token: token)
        let jwts = [response.sessionJwt, response.refreshJwt].compactMap { $0 }
        return try jwts.map { try _Token(jwt: $0) }
    }

    // MARK: - Cross-Device
    
    func signUpCrossDevice(with method: DeliveryMethod, identifier: String, user: User, uri: String?) async throws -> [Token] {
        let pendingRef = try await callSignUp(with: method, identifier: identifier, user: user, uri: uri)
        return try await pollForSession(pendingRef)
    }
    
    func signInCrossDevice(with method: DeliveryMethod, identifier: String, uri: String?) async throws -> [Token] {
        let pendingRef = try await callSignIn(with: method, identifier: identifier, uri: uri)
        return try await pollForSession(pendingRef)
    }
    
    func signUpOrInCrossDevice(with method: DeliveryMethod, identifier: String, uri: String?) async throws -> [Token] {
        let pendingRef = try await callSignUpOrIn(with: method, identifier: identifier, uri: uri)
        return try await pollForSession(pendingRef)
    }
    
    // MARK: - Utility Methods
    
    @discardableResult
    private func callSignUp(with method: DeliveryMethod, identifier: String, user: User, uri: String?) async throws -> String {
        let response = try await client.magicLinkSignUp(with: method, identifier: identifier, user: user, uri: uri)
        return response.pendingRef
    }
    
    @discardableResult
    private func callSignIn(with method: DeliveryMethod, identifier: String, uri: String?) async throws -> String {
        let response = try await client.magicLinkSignIn(with: method, identifier: identifier, uri: uri)
        return response.pendingRef
    }
    
    @discardableResult
    private func callSignUpOrIn(with method: DeliveryMethod, identifier: String, uri: String?) async throws -> String {
        let response = try await client.magicLinkSignUpOrIn(with: method, identifier: identifier, uri: uri)
        return response.pendingRef
    }
    
    private func pollForSession(_ pendingRef: String) async throws -> [Token] {
        let pollingEndsAt = Date() + 600 // 10 minute polling window
        while pollingEndsAt > .now {
            do {
                let response = try await client.magicLinkPendingSession(pendingRef: pendingRef)
                let jwts = [response.sessionJwt, response.refreshJwt].compactMap { $0 }
                return try jwts.map { try _Token(jwt: $0) }
            } catch {}
            try await Task.sleep(nanoseconds: 1_000_000_000) // Sleep for 1 seconds
        }
        
        throw NetworkError.timeout // TODO: This should be a different error once we have our public errors ready
    }
}
