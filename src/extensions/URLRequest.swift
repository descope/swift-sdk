
import Foundation

public extension URLRequest {
    mutating func addAuthorizationHeader(from session: DescopeSession) {
        let header = authorizationHeader(projectId: session.projectId, jwt: session.sessionJwt)
        addValue(header.value, forHTTPHeaderField: header.field)
    }
    
    mutating func addAuthorizationHeader(from token: DescopeToken) {
        let header = authorizationHeader(projectId: token.projectId, jwt: token.jwt)
        addValue(header.value, forHTTPHeaderField: header.field)
    }
}

private func authorizationHeader(projectId: String, jwt: String) -> (field: String, value: String) {
    return ("Authorization", "Bearer \(projectId):\(jwt)")
}
