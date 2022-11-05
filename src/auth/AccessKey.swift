
import Foundation

class AccessKey: DescopeAccessKey {
    let client: DescopeClient
    
    init(client: DescopeClient) {
        self.client = client
    }
    
    func exchange(accessKey: String) async throws -> DescopeSession {
        return try await client.accessKeyExchange(accessKey).convert()
    }
}

private extension DescopeClient.AccessKeyExchangeResponse {
    func convert() throws -> DescopeSession {
        let sessionToken = try Token(jwt: sessionJwt)
        return Session(sessionToken: sessionToken, refreshToken: nil)
    }
}
