
class OTP: DescopeOTP {
    let client: DescopeClient
    
    init(client: DescopeClient) {
        self.client = client
    }

    func signUp(with method: DeliveryMethod, loginId: String, user: User) async throws -> String {
        return try await client.otpSignUp(with: method, loginId: loginId, user: user).convert(method: method)
    }
    
    func signIn(with method: DeliveryMethod, loginId: String) async throws -> String {
        return try await client.otpSignIn(with: method, loginId: loginId).convert(method: method)
    }
    
    func signUpOrIn(with method: DeliveryMethod, loginId: String) async throws -> String {
        return try await client.otpSignUpIn(with: method, loginId: loginId).convert(method: method)
    }
    
    func verify(with method: DeliveryMethod, loginId: String, code: String) async throws -> DescopeSession {
        return try await client.otpVerify(with: method, loginId: loginId, code: code).convert()
    }
    
    func updateEmail(_ email: String, loginId: String, refreshJwt: String, updateOptions: UpdateOptions?) async throws -> String {
        return try await client.otpUpdateEmail(email, loginId: loginId, refreshJwt: refreshJwt, updateOptions: updateOptions).convert(method: .email)
    }
    
    func updatePhone(_ phone: String, with method: DeliveryMethod, loginId: String, refreshJwt: String, updateOptions: UpdateOptions?) async throws -> String {
        return try await client.otpUpdatePhone(phone, with: method, loginId: loginId, refreshJwt: refreshJwt, updateOptions: updateOptions).convert(method: method)
    }
}
