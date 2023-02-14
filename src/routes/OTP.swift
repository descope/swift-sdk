
class OTP: DescopeOTP {
    let client: DescopeClient
    
    init(client: DescopeClient) {
        self.client = client
    }

    func signUp(with method: DeliveryMethod, loginId: String, user: User) async throws {
        try await client.otpSignUp(with: method, loginId: loginId, user: user)
    }
    
    func signIn(with method: DeliveryMethod, loginId: String) async throws {
        try await client.otpSignIn(with: method, loginId: loginId)
    }
    
    func signUpOrIn(with method: DeliveryMethod, loginId: String) async throws {
        try await client.otpSignUpIn(with: method, loginId: loginId)
    }
    
    func verify(with method: DeliveryMethod, loginId: String, code: String) async throws -> DescopeSession {
        return try await client.otpVerify(with: method, loginId: loginId, code: code).convert()
    }
    
    func updateEmail(_ email: String, loginId: String, refreshJwt: String) async throws {
        try await client.otpUpdateEmail(email, loginId: loginId, refreshJwt: refreshJwt)
    }
    
    func updatePhone(_ phone: String, with method: DeliveryMethod, loginId: String, refreshJwt: String) async throws {
        try await client.otpUpdatePhone(phone, with: method, loginId: loginId, refreshJwt: refreshJwt)
    }
}
