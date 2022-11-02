
import Foundation

class Auth: DescopeAuth {
    let client: DescopeClient
    
    init(client: DescopeClient) {
        self.client = client
    }
    
    func me(token: String) async throws -> MeResponse {
        return try await client.me(token).convert()
    }
}

private extension DescopeClient.UserResponse {
    func convert() -> MeResponse {
        var me = MeResponse(userId: userId, externalIds: externalIds, name: name)
        if let value = email {
            me.email = (value: value, isVerified: verifiedEmail)
        }
        if let value = phone {
            me.phone = (value: value, isVerified: verifiedPhone)
        }
        return me
    }
}

extension DescopeClient.JWTResponse {
    func tokens() throws -> [DescopeToken] {
        let jwts = [self.sessionJwt, self.refreshJwt].compactMap { $0 }
        return try jwts.map { try Token(jwt: $0) }
    }
}
