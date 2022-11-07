
class OTP: DescopeOTP {
    let client: DescopeClient
    
    init(client: DescopeClient) {
        self.client = client
    }

    func signUp(with method: DeliveryMethod, identifier: String, user: User) async throws {
        try await client.otpSignUp(with: method, identifier: identifier, user: user)
    }
    
    func signIn(with method: DeliveryMethod, identifier: String) async throws {
        try await client.otpSignIn(with: method, identifier: identifier)
    }
    
    func signUpOrIn(with method: DeliveryMethod, identifier: String) async throws {
        try await client.otpSignUpIn(with: method, identifier: identifier)
    }
    
    func verify(with method: DeliveryMethod, identifier: String, code: String) async throws -> DescopeSession {
        return try await client.otpVerify(with: method, identifier: identifier, code: code).convert()
    }
    
    func updateEmail(_ email: String, identifier: String, refreshToken: String) async throws {
        try await client.otpUpdateEmail(email, identifier: identifier, refreshToken: refreshToken)
    }
    
    func updatePhone(_ phone: String, with method: DeliveryMethod, identifier: String, refreshToken: String) async throws {
        try await client.otpUpdatePhone(phone, with: method, identifier: identifier, refreshToken: refreshToken)
    }
}
