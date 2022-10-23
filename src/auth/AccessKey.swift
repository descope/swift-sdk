
import Foundation

class AccessKey: DescopeAccessKey {
    let client: DescopeClient
    
    init(client: DescopeClient) {
        self.client = client
    }
    
    func exchange(accessKey: String) async throws -> Token {
        return try await client.accessKeyExchange(accessKey).convert()
    }
}

private extension DescopeClient.AccessKeyExchangeResponse {
    func convert() throws -> Token {
        return try _Token(jwt: sessionJwt)
    }
}
