
class Auth: DescopeAuth {
    let client: DescopeClient
    
    init(client: DescopeClient) {
        self.client = client
    }
    
    func me(refreshJwt: String) async throws -> MeResponse {
        return try await client.me(refreshJwt: refreshJwt).convert()
    }

    func refreshSession(refreshJwt: String) async throws -> DescopeSession {
        return try await client.refresh(refreshJwt: refreshJwt).convert()
    }

    func logout(refreshJwt: String) async throws {
        try await client.logout(refreshJwt: refreshJwt)
    }
}

private extension DescopeClient.UserResponse {
    func convert() -> MeResponse {
        var me = MeResponse(userId: userId, loginIds: loginIds, name: name, picture: picture, createdTime: createdTime)
        if let value = email {
            me.email = (value: value, isVerified: verifiedEmail)
        }
        if let value = phone {
            me.phone = (value: value, isVerified: verifiedPhone)
        }
        return me
    }
}
