
final class Auth: DescopeAuth {
    let client: DescopeClient
    
    init(client: DescopeClient) {
        self.client = client
    }
    
    func me(refreshJwt: String) async throws -> DescopeUser {
        return try await client.me(refreshJwt: refreshJwt).convert()
    }

    func tenants(by request: TenantsRequest, refreshJwt: String) async throws -> [DescopeTenant] {
        var dct = false
        var tenantIds: [String] = []
        switch request {
        case .selected: dct = true
        case .tenantIds(let ids): tenantIds = ids
        }
        return try await client.tenants(dct: dct, tenantIds: tenantIds, refreshJwt: refreshJwt).convert()
    }

    func refreshSession(refreshJwt: String) async throws -> RefreshResponse {
        return try await client.refresh(refreshJwt: refreshJwt).convert()
    }

    func revokeSessions(_ revoke: RevokeType, refreshJwt: String) async throws {
        try await client.logout(type: revoke, refreshJwt: refreshJwt)
    }
}
