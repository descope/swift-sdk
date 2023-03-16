
extension DescopeClient.JWTResponse {
    func convert() throws -> DescopeSession {
        guard let refreshJwt else { throw DescopeError.decodeError.with(message: "Missing refresh JWT") }
        return try DescopeSession(sessionJwt: sessionJwt, refreshJwt: refreshJwt)
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
