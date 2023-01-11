
import Foundation

class DescopeClient: HTTPClient {
    let config: DescopeConfig
    
    init(config: DescopeConfig, session: URLSession? = nil) {
        self.config = config
        super.init(baseURL: config.baseURL, session: session)
    }
    
    // MARK: - OTP
    
    func otpSignUp(with method: DeliveryMethod, loginId: String, user: User) async throws {
        try await post("otp/signup/\(method.rawValue)", body: [
            "loginId": loginId,
            "user": user.dictValue,
        ])
    }
    
    func otpSignIn(with method: DeliveryMethod, loginId: String) async throws {
        try await post("otp/signin/\(method.rawValue)", body: [
            "loginId": loginId
        ])
    }
    
    func otpSignUpIn(with method: DeliveryMethod, loginId: String) async throws {
        try await post("otp/signup-in/\(method.rawValue)", body: [
            "loginId": loginId
        ])
    }
    
    func otpVerify(with method: DeliveryMethod, loginId: String, code: String) async throws -> JWTResponse {
        return try await post("otp/verify/\(method.rawValue)", body: [
            "loginId": loginId,
            "code": code,
        ])
    }
    
    func otpUpdateEmail(_ email: String, loginId: String, refreshToken: String) async throws {
        try await post("otp/update/email", headers: authorization(with: refreshToken), body: [
            "loginId": loginId,
            "email": email,
        ])
    }
    
    func otpUpdatePhone(_ phone: String, with method: DeliveryMethod, loginId: String, refreshToken: String) async throws {
        try await post("otp/update/phone/\(method.rawValue)", headers: authorization(with: refreshToken), body: [
            "loginId": loginId,
            "phone": phone,
        ])
    }
    
    // MARK: - TOTP
    
    struct TOTPResponse: JSONResponse {
        var provisioningURL: String
        var image: String // This is a base64 encoded image
        var key: String
    }
    
    func totpSignUp(loginId: String, user: User) async throws -> TOTPResponse {
        return try await post("totp/signup", body: [
            "loginId": loginId,
            "user": user.dictValue,
        ])
    }
    
    func totpVerify(loginId: String, code: String) async throws -> JWTResponse {
        return try await post("totp/verify", body: [
            "loginId": loginId,
            "code": code,
        ])
    }
    
    func totpUpdate(loginId: String, refreshToken: String) async throws {
        try await post("totp/update", headers: authorization(with: refreshToken), body: [
            "loginId": loginId,
        ])
    }
    
    // MARK: - Magic Link
    
    struct MagicLinkResponse: JSONResponse {
        var pendingRef: String
    }
    
    func magicLinkSignUp(with method: DeliveryMethod, loginId: String, user: User, uri: String?) async throws -> MagicLinkResponse {
        return try await post("magiclink/signup/\(method.rawValue)", body: [
            "loginId": loginId,
            "user": user.dictValue,
            "uri": uri,
        ])
    }
    
    func magicLinkSignIn(with method: DeliveryMethod, loginId: String, uri: String?) async throws -> MagicLinkResponse {
        try await post("magiclink/signin/\(method.rawValue)", body: [
            "loginId": loginId,
            "uri": uri,
        ])
    }
    
    func magicLinkSignUpOrIn(with method: DeliveryMethod, loginId: String, uri: String?) async throws -> MagicLinkResponse {
        try await post("magiclink/signup-in/\(method.rawValue)", body: [
            "loginId": loginId,
            "uri": uri,
        ])
    }
    
    func magicLinkVerify(token: String) async throws -> JWTResponse {
        return try await post("magiclink/verify", body: [
            "token": token,
        ])
    }
    
    func magicLinkUpdateEmail(_ email: String, loginId: String, refreshToken: String) async throws {
        try await post("magiclink/update/email", headers: authorization(with: refreshToken), body: [
            "loginId": loginId,
            "email": email,
        ])
    }
    
    func magicLinkUpdatePhone(_ phone: String, with method: DeliveryMethod, loginId: String, refreshToken: String) async throws {
        try await post("magiclink/update/phone/\(method.rawValue)", headers: authorization(with: refreshToken), body: [
            "loginId": loginId,
            "phone": phone,
        ])
    }
    
    func magicLinkPendingSession(pendingRef: String) async throws -> JWTResponse {
        return try await post("magiclink/pending-session", body: [
            "pendingRef": pendingRef,
        ])
    }
    
    // MARK: - OAuth
    
    struct OAuthResponse: JSONResponse {
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
    
    struct SSOResponse: JSONResponse {
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
    
    struct AccessKeyExchangeResponse: JSONResponse {
        var sessionJwt: String
    }
    
    func accessKeyExchange(_ accessKey: String) async throws -> AccessKeyExchangeResponse {
        return try await post("accesskey/exchange", headers: authorization(with: accessKey))
    }
    
    // MARK: - Others
    
    func me(_ refreshToken: String) async throws -> UserResponse {
        return try await get("me", headers: authorization(with: refreshToken))
    }
    
    // MARK: - Shared
    
    static let refreshCookieName = "DSR"
    
    struct JWTResponse: JSONResponse {
        var sessionJwt: String
        var refreshJwt: String?
        var user: UserResponse?
        var firstSeen: Bool
        
        mutating func setValues(from response: HTTPURLResponse) {
            guard let url = response.url, let fields = response.allHeaderFields as? [String: String] else { return }
            let cookies = HTTPCookie.cookies(withResponseHeaderFields: fields, for: url)
            for cookie in cookies where cookie.name == refreshCookieName {
                refreshJwt = cookie.value
            }
        }
    }
    
    struct UserResponse: JSONResponse {
        var userId: String
        var loginIds: [String]
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
