
extension DescopeClient.JWTResponse {
    func convert() throws -> DescopeSession {
        let sessionToken = try Token(jwt: sessionJwt)
        var refreshToken: Token?
        if let refreshJwt {
            refreshToken = try Token(jwt: refreshJwt)
        }
        return Session(sessionToken: sessionToken, refreshToken: refreshToken)
    }
}
