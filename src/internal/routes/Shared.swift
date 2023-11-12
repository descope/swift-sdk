
import Foundation

protocol Route {
    var client: DescopeClient { get }
}

extension Route {
    func log(_ level: DescopeLogger.Level, _ message: StaticString, _ values: Any?...) {
        client.config.logger?.log(level, message, values)
    }
}

extension DescopeClient.UserResponse {
    func convert() -> DescopeUser {
        let createdAt = Date(timeIntervalSince1970: TimeInterval(createdTime))
        var me = DescopeUser(userId: userId, loginIds: loginIds, createdAt: createdAt, isVerifiedEmail: false, isVerifiedPhone: false)
        if let name, !name.isEmpty {
            me.name = name
        }
        if let picture, let url = URL(string: picture) {
            me.picture = url
        }
        if let email, !email.isEmpty {
            me.email = email
            me.isVerifiedEmail = verifiedEmail
        }
        if let phone, !phone.isEmpty {
            me.phone = phone
            me.isVerifiedPhone = verifiedPhone
        }
        return me
    }
}

extension DescopeClient.JWTResponse {
    func convert() throws -> AuthenticationResponse {
        guard let sessionJwt, !sessionJwt.isEmpty else { throw DescopeError.decodeError.with(message: "Missing session JWT") }
        guard let refreshJwt, !refreshJwt.isEmpty else { throw DescopeError.decodeError.with(message: "Missing refresh JWT") }
        guard let user else { throw DescopeError.decodeError.with(message: "Missing user details") }
        return try AuthenticationResponse(sessionToken: Token(jwt: sessionJwt), refreshToken: Token(jwt: refreshJwt), isFirstAuthentication: firstSeen, user: user.convert())
    }
    
    func convert() throws -> RefreshResponse {
        guard let sessionJwt, !sessionJwt.isEmpty else { throw DescopeError.decodeError.with(message: "Missing session JWT") }
        var refreshToken: DescopeToken?
        if let refreshJwt, !refreshJwt.isEmpty {
            refreshToken = try Token(jwt: refreshJwt)
        }
        return try RefreshResponse(sessionToken: Token(jwt: sessionJwt), refreshToken: refreshToken)
    }
}

extension DescopeClient.MaskedAddress {
    func convert(method: DeliveryMethod) throws -> String {
        switch method {
        case .email:
            guard let maskedEmail else { throw DescopeError.decodeError.with(message: "Missing masked email") }
            return maskedEmail
        case .sms, .whatsapp:
            guard let maskedPhone else { throw DescopeError.decodeError.with(message: "Missing masked phone") }
            return maskedPhone
        }
    }
}

extension [SignInOptions] {
    func convert() throws -> (refreshJwt: String?, loginOptions: DescopeClient.LoginOptions?) {
        guard !isEmpty else { return (nil, nil) }
        var refreshJwt: String?
        var loginOptions = DescopeClient.LoginOptions()
        for option in self {
            switch option {
            case .customClaims(let dict):
                guard JSONSerialization.isValidJSONObject(dict) else { throw DescopeError.encodeError.with(message: "Invalid custom claims payload") }
                loginOptions.customClaims = dict
            case .stepup(let value):
                loginOptions.stepup = true
                refreshJwt = value
            case .mfa(let value):
                loginOptions.mfa = true
                refreshJwt = value
            }
        }
        return (refreshJwt, loginOptions)
    }
}
