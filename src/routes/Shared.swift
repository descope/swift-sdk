
extension DescopeClient.JWTResponse {
    func convert() throws -> DescopeSession {
        guard let refreshJwt else { throw DescopeError.decodeError.with(message: "Missing refresh JWT") }
        return try DescopeSession(sessionJwt: sessionJwt, refreshJwt: refreshJwt)
    }
}

extension DescopeClient.EnchantedLinkResponse {
    func convert() throws -> EnchantedLinkResponse {
        return try EnchantedLinkResponse(linkId: linkId, pendingRef: pendingRef)
    }
}
