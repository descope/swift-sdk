
import Foundation

class DescopeClient: HttpClient {
    let config: DescopeConfig
    
    init(config: DescopeConfig, session: URLSession? = nil) {
        self.config = config
        super.init(baseURL: config.baseURL, session: session)
    }
    
    // MARK: - OTP
    
    func otpSignUp(with method: DeliveryMethod, identifier: String, user: User) async throws {
        try await post("/v1/auth/otp/signup/\(method.name)", body: [
            "externalId": identifier,
            "user": user.dictValue,
        ])
    }
    
    func otpSignIn(with method: DeliveryMethod, identifier: String) async throws {
        try await post("/v1/auth/otp/signin/\(method.name)", body: [
            "externalId": identifier
        ])
    }
    
    func otpSignUpIn(with method: DeliveryMethod, identifier: String) async throws {
        try await post("/v1/auth/otp/signup-in/\(method.name)", body: [
            "externalId": identifier
        ])
    }
    
    func otpVerify(with method: DeliveryMethod, identifier: String, code: String) async throws -> JWTResponse {
        return try await post("/v1/auth/otp/verify/\(method.name)", body: [
            "externalId": identifier,
            "code": code,
        ])
    }
    
    func otpUpdateEmail(_ email: String, identifier: String, refreshToken: String) async throws {
        try await post("/v1/auth/otp/update/email", headers: authorization(with: refreshToken), body: [
            "externalId": identifier,
            "email": email,
        ])
    }
    
    func otpUpdatePhone(_ phone: String, with method: DeliveryMethod, identifier: String, refreshToken: String) async throws {
        try await post("/v1/auth/otp/update/phone/\(method.name)", headers: authorization(with: refreshToken), body: [
            "externalId": identifier,
            "phone": phone,
        ])
    }
    
    // MARK: - TOTP
    
    struct TOTPResponse: Decodable {
        var provisioningURL: String
        var image: String // This is a base64 encoded image
        var key: String
    }
    
    func totpSignUp(identifier: String, user: User) async throws -> TOTPResponse {
        return try await post("/v1/auth/totp/signup", body: [
            "externalId": identifier,
            "user": user.dictValue,
        ])
    }
    
    func totpVerify(identifier: String, code: String) async throws -> JWTResponse {
        return try await post("/v1/auth/totp/verify", body: [
            "externalId": identifier,
            "code": code,
        ])
    }
    
    func totpUpdate(identifier: String, refreshToken: String) async throws {
        try await post("/v1/auth/totp/update", headers: authorization(with: refreshToken), body: [
            "externalId": identifier,
        ])
    }
    
    // MARK: - Magic Link
    
    struct MagicLinkResponse: Decodable {
        var pendingRef: String
    }
    
    func magicLinkSignUp(with method: DeliveryMethod, identifier: String, user: User, uri: String?) async throws -> MagicLinkResponse {
        return try await post("/v1/auth/magiclink/signup/\(method.name)", body: [
            "externalId": identifier,
            "user": user.dictValue,
            "uri": uri,
        ])
    }
    
    func magicLinkSignIn(with method: DeliveryMethod, identifier: String, uri: String?) async throws -> MagicLinkResponse {
        try await post("/v1/auth/magiclink/signin/\(method.name)", body: [
            "externalId": identifier,
            "uri": uri,
        ])
    }
    
    func magicLinkSignUpOrIn(with method: DeliveryMethod, identifier: String, uri: String?) async throws -> MagicLinkResponse {
        try await post("/v1/auth/magiclink/signup-in/\(method.name)", body: [
            "externalId": identifier,
            "uri": uri,
        ])
    }
    
    func magicLinkVerify(token: String) async throws -> JWTResponse {
        return try await post("/v1/auth/magiclink/verify", body: [
            "token": token,
        ])
    }
    
    func magicLinkUpdateEmail(_ email: String, identifier: String, refreshToken: String) async throws {
        try await post("/v1/auth/magiclink/update/email", headers: authorization(with: refreshToken), body: [
            "externalId": identifier,
            "email": email,
        ])
    }
    
    func magicLinkUpdatePhone(_ phone: String, with method: DeliveryMethod, identifier: String, refreshToken: String) async throws {
        try await post("/v1/auth/magiclink/update/phone/\(method.name)", headers: authorization(with: refreshToken), body: [
            "externalId": identifier,
            "phone": phone,
        ])
    }
    
    func magicLinkPendingSession(pendingRef: String) async throws -> JWTResponse {
        return try await post("/v1/auth/magiclink/pending-session", body: [
            "pendingRef": pendingRef,
        ])
    }
    
    // MARK: - OAuth
    
    struct OAuthResponse: Decodable {
        var url: String
    }
    
    func oauthStart(provider: OAuthProvider, redirectUrl: String?) async throws -> OAuthResponse {
        return try await post("/v1/auth/oauth/authorize", params: [
            "provider": provider.rawValue,
            "redirectURL": redirectUrl,
        ].compactMapValues{ $0 }, body: [:
        ])
    }
    
    func oauthExchange(code: String) async throws -> JWTResponse {
        return try await post("/v1/auth/oauth/exchange", body: [
            "code": code
        ])
    }

    // MARK: - Access Key
    
    struct AccessKeyExchangeResponse: Decodable {
        var sessionJwt: String
    }
    
    func accessKeyExchange(_ accessKey: String) async throws -> AccessKeyExchangeResponse {
        return try await get("/v1/auth/accesskey/exchange", headers: authorization(with: accessKey))
    }
    
    // MARK: - Others
    
    func me(_ token: String) async throws -> UserResponse {
        return try await get("/v1/auth/me", headers: authorization(with: token))
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
        return DescopeError.from(responseData: data)
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

private extension User {
    var dictValue: [String: Any?] {
        return [
            "name": name,
            "phone": phone,
            "email": email,
        ]
    }
}
