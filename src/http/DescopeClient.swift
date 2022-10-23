
import Foundation

class DescopeClient: HttpClient {
    let config: DescopeConfig
    
    init(config: DescopeConfig) {
        self.config = config
        super.init(baseURL: "https://localhost:8443/v1")
    }
    
    // MARK: - OTP
    
    func otpSignUp(with method: DeliveryMethod, identifier: String, user: User) async throws {
        try await post("auth/otp/signin/\(method.name)", body: [
            "externalId": identifier,
            "user": [
                "name": user.name,
                "phone": user.phone,
                "email": user.email,
            ],
        ])
    }
    
    func otpSignIn(with method: DeliveryMethod, identifier: String) async throws {
        try await post("auth/otp/signin/\(method.name)", body: [
            "externalId": identifier
        ])
    }
    
    func otpSignUpIn(with method: DeliveryMethod, identifier: String) async throws {
        try await post("auth/otp/signup-in/\(method.name)", body: [
            "externalId": identifier
        ])
    }
    
    func otpVerify(with method: DeliveryMethod, identifier: String, code: String) async throws -> JWTResponse {
        return try await post("auth/otp/verify/\(method.name)", body: [
            "externalId": identifier,
            "code": code,
        ])
    }
    
    func otpUpdateEmail(_ email: String, identifier: String, refreshToken: String) async throws {
        try await post("auth/otp/update/email", headers: authorization(with: refreshToken), body: [
            "externalId": identifier,
            "email": email,
        ])
    }
    
    func otpUpdatePhone(_ phone: String, with method: DeliveryMethod, identifier: String, refreshToken: String) async throws {
        try await post("auth/otp/update/phone/\(method.name)", headers: authorization(with: refreshToken), body: [
            "externalId": identifier,
            "phone": phone,
        ])
    }
    
    // MARK: - Access Key
    
    struct AccessKeyExchangeResponse: Decodable {
        var sessionJwt: String
    }
    
    func accessKeyExchange(_ accessKey: String) async throws -> AccessKeyExchangeResponse {
        return try await get("auth/accesskey/exchange", headers: authorization(with: accessKey))
    }
    
    // MARK: - Others
    
    func me(_ token: String) async throws -> UserResponse {
        return try await get("auth/me", headers: authorization(with: token))
    }
    
    // MARK: - Shared
    
    struct JWTResponse: Decodable {
        var sessionJwt: String
        var refreshJwt: String?
        var user: UserResponse?
        var firstSeen: Bool
    }
    
    struct UserResponse: Decodable {
        var userId: String
        var externalIds: [String]
        var name: String?
        var email: String?
        var verifiedEmail: Bool = false
        var phone: String?
        var verifiedPhone: Bool = false
    }
    
    // MARK: - Internal
    
    override var defaultHeaders: [String: String] {
        return ["Authorization": "Bearer \(config.projectId)"]
    }
    
    override func errorForResponseData(_ data: Data) -> Error? {
        guard let userInfo = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else { return nil }
        return ServerError(errorCode: 0, errorUserInfo: userInfo)
    }
    
    private func authorization(with token: String) -> [String: String] {
        return ["Authorization": "Bearer \(config.projectId):\(token)"]
    }
}

private extension DeliveryMethod {
    var name: String {
        switch self {
        case .email: return "email"
        case .sms: return "sms"
        case .whatsapp: return "whatsapp"
        }
    }
}
