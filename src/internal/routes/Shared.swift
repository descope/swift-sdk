
import Foundation

protocol Route {
    var client: DescopeClient { get }
}

extension Route {
    func log(_ level: DescopeConfig.Logger.Level, _ message: StaticString, _ values: Any?...) {
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
        guard let refreshJwt else { throw DescopeError.decodeError.with(message: "Missing refresh JWT") }
        guard let user else { throw DescopeError.decodeError.with(message: "Missing user details") }
        return try AuthenticationResponse(sessionToken: Token(jwt: sessionJwt), refreshToken: Token(jwt: refreshJwt), isFirstAuthentication: firstSeen, user: user.convert())
    }
}

extension DescopeClient.JWTResponse {
    func convert() throws -> RefreshResponse {
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
