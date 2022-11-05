
import Foundation

class DescopeClient: HTTPClient {
    let config: DescopeConfig
    
    init(config: DescopeConfig, session: URLSession? = nil) {
        self.config = config
        super.init(baseURL: config.baseURL, session: session)
    }
    
    // MARK: - OTP
    
    func otpSignUp(with method: DeliveryMethod, identifier: String, user: User) async throws {
        try await post("otp/signup/\(method.rawValue)", body: [
            "externalId": identifier,
            "user": user.dictValue,
        ])
    }
    
    func otpSignIn(with method: DeliveryMethod, identifier: String) async throws {
        try await post("otp/signin/\(method.rawValue)", body: [
            "externalId": identifier
        ])
    }
    
    func otpSignUpIn(with method: DeliveryMethod, identifier: String) async throws {
        try await post("otp/signup-in/\(method.rawValue)", body: [
            "externalId": identifier
        ])
    }
    
    func otpVerify(with method: DeliveryMethod, identifier: String, code: String) async throws -> JWTResponse {
        return try await post("otp/verify/\(method.rawValue)", body: [
            "externalId": identifier,
            "code": code,
        ])
    }
    
    func otpUpdateEmail(_ email: String, identifier: String, refreshToken: String) async throws {
        try await post("otp/update/email", headers: authorization(with: refreshToken), body: [
            "externalId": identifier,
            "email": email,
        ])
    }
    
    func otpUpdatePhone(_ phone: String, with method: DeliveryMethod, identifier: String, refreshToken: String) async throws {
        try await post("otp/update/phone/\(method.rawValue)", headers: authorization(with: refreshToken), body: [
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
        return try await post("totp/signup", body: [
            "externalId": identifier,
            "user": user.dictValue,
        ])
    }
    
    func totpVerify(identifier: String, code: String) async throws -> JWTResponse {
        return try await post("totp/verify", body: [
            "externalId": identifier,
            "code": code,
        ])
    }
    
    func totpUpdate(identifier: String, refreshToken: String) async throws {
        try await post("totp/update", headers: authorization(with: refreshToken), body: [
            "externalId": identifier,
        ])
    }
    
    // MARK: - Magic Link
    
    struct MagicLinkResponse: Decodable {
        var pendingRef: String
    }
    
    func magicLinkSignUp(with method: DeliveryMethod, identifier: String, user: User, uri: String?) async throws -> MagicLinkResponse {
        return try await post("magiclink/signup/\(method.rawValue)", body: [
            "externalId": identifier,
            "user": user.dictValue,
            "uri": uri,
        ])
    }
    
    func magicLinkSignIn(with method: DeliveryMethod, identifier: String, uri: String?) async throws -> MagicLinkResponse {
        try await post("magiclink/signin/\(method.rawValue)", body: [
            "externalId": identifier,
            "uri": uri,
        ])
    }
    
    func magicLinkSignUpOrIn(with method: DeliveryMethod, identifier: String, uri: String?) async throws -> MagicLinkResponse {
        try await post("magiclink/signup-in/\(method.rawValue)", body: [
            "externalId": identifier,
            "uri": uri,
        ])
    }
    
    func magicLinkVerify(token: String) async throws -> JWTResponse {
        return try await post("magiclink/verify", body: [
            "token": token,
        ])
    }
    
    func magicLinkUpdateEmail(_ email: String, identifier: String, refreshToken: String) async throws {
        try await post("magiclink/update/email", headers: authorization(with: refreshToken), body: [
            "externalId": identifier,
            "email": email,
        ])
    }
    
    func magicLinkUpdatePhone(_ phone: String, with method: DeliveryMethod, identifier: String, refreshToken: String) async throws {
        try await post("magiclink/update/phone/\(method.rawValue)", headers: authorization(with: refreshToken), body: [
            "externalId": identifier,
            "phone": phone,
        ])
    }
    
    func magicLinkPendingSession(pendingRef: String) async throws -> JWTResponse {
        return try await post("magiclink/pending-session", body: [
            "pendingRef": pendingRef,
        ])
    }
    
    // MARK: - OAuth
    
    struct OAuthResponse: Decodable {
        var url: String
    }
    
    func oauthStart(provider: OAuthProvider, redirectURL: String?) async throws -> OAuthResponse {
        return try await post("oauth/authorize", params: [
            "provider": provider.rawValue,
            "redirectURL": redirectURL,
        ])
    }
    
    func oauthExchange(code: String) async throws -> JWTResponse {
        return try await post("oauth/exchange", body: [
            "code": code
        ])
    }

    // MARK: - SSO
    
    struct SSOResponse: Decodable {
        var url: String
    }
    
    func ssoStart(emailOrTenantName: String, redirectURL: String?) async throws -> OAuthResponse {
        return try await post("/v1/auth/saml/authorize", params: [
            "tenant": emailOrTenantName,
            "redirectURL": redirectURL,
        ])
    }
    
    func ssoExchange(code: String) async throws -> JWTResponse {
        return try await post("/v1/auth/saml/exchange", body: [
            "code": code
        ])
    }
    
    // MARK: - Access Key
    
    struct AccessKeyExchangeResponse: Decodable {
        var sessionJwt: String
    }
    
    func accessKeyExchange(_ accessKey: String) async throws -> AccessKeyExchangeResponse {
        return try await post("accesskey/exchange", headers: authorization(with: accessKey))
    }
    
    // MARK: - Others
    
    func me(_ token: String) async throws -> UserResponse {
        return try await get("me", headers: authorization(with: token))
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
    
    override var basePath: String {
        return "v1/auth"
    }
    
    override var defaultHeaders: [String: String] {
        return [
            "Authorization": "Bearer \(config.projectId)",
            "x-descope-sdk-name": "swift",
            "x-descope-sdk-version": Descope.version,
        ]
    }
    
    override func errorForResponseData(_ data: Data) -> Error? {
        return DescopeError.from(responseData: data)
    }
    
    private func authorization(with token: String) -> [String: String] {
        return ["Authorization": "Bearer \(config.projectId):\(token)"]
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
