
import Foundation

enum TokenError: Error {
    case invalidFormat
    case invalidEncoding
    case invalidData
    case missingClaim(String)
    case invalidClaim(String)
    case missingTenant(String)
    case invalidTenant(String)
}

class Token: DescopeToken {
    let jwt: String
    let id: String
    let projectId: String
    let expiresAt: Date?
    let claims: [String: Any]
    let allClaims: [String: Any]
    
    // TODO wrap error in DescopeError?
    init(jwt: String) throws {
        let dict = try decodeJWT(jwt)
        self.jwt = jwt
        self.id = try getClaim(.subject, in: dict)
        self.projectId = try getClaim(.issuer, in: dict)
        self.expiresAt = try? Date(timeIntervalSince1970: getClaim(.expiration, in: dict))
        self.claims = dict.filter { Claim.isCustom($0.key) }
        self.allClaims = dict
    }
    
    var isExpired: Bool {
        guard let expiresAt else { return false }
        return expiresAt.timeIntervalSinceNow <= 0
    }
    
    func permissions(forTenant tenant: String?) -> [String] {
        let items = try? authorizationItems(forTenant: tenant, claim: .permissions)
        return items ?? []
    }
    
    func roles(forTenant tenant: String?) -> [String] {
        let items = try? authorizationItems(forTenant: tenant, claim: .roles)
        return items ?? []
    }
    
    private func authorizationItems(forTenant tenant: String?, claim: Claim) throws -> [String] {
        let items: [String]
        if let tenant {
            items = try getValueForTenant(tenant, key: claim.rawValue) ?? []
        } else {
            items = try getClaim(claim, in: allClaims)
        }
        return items
    }
    
    private func getValueForTenant<T>(_ tenant: String, key: String) throws -> T {
        let tenants = try getTenants()
        guard let object = tenants[tenant] else { throw TokenError.missingTenant(tenant) }
        guard let info = object as? [String: Any] else { throw TokenError.invalidTenant(tenant) }
        guard let value = info[key] as? T else { throw TokenError.invalidTenant(tenant) }
        return value
    }
    
    private func getTenants() throws -> [String: Any] {
        return try getClaim(.tenants, in: allClaims)
    }
}

// Description

extension Token: CustomStringConvertible {
    var description: String {
        var expires = "expires=Never"
        if let expiresAt {
            let tag = expiresAt.timeIntervalSinceNow > 0 ? "expires" : "expired"
            expires = "\(tag)=\(expiresAt)"
        }
        return "DescopeToken(id=\(id) project=\(projectId) \(expires))"
    }
}

extension TokenError: CustomStringConvertible {
    var description: String {
        switch self {
        case .invalidFormat: return "Invalid token format"
        case .invalidEncoding: return "Invalid token encoding"
        case .invalidData: return "Invalid token data"
        case .missingClaim(let claim): return "Missing \(claim) claim in token"
        case .invalidClaim(let claim): return "Invalid \(claim) claim in token"
        case .missingTenant(let tenant): return "Tenant \(tenant) not found in token"
        case .invalidTenant(let tenant): return "Invalid data for tenant \(tenant) in token"
        }
    }
}

// Claims

private enum Claim: String {
    case audience = "aud"
    case subject = "sub"
    case issuer = "iss"
    case issuedAt = "iat"
    case expiration = "exp"
    case tenants = "tenants"
    case permissions = "permissions"
    case roles = "roles"
    
    static func isCustom(_ name: String) -> Bool {
        return Claim(rawValue: name) == nil
    }
}

private func getClaim<T>(_ claim: Claim, in dict: [String: Any]) throws -> T {
    return try getClaim(claim.rawValue, in: dict)
}

private func getClaim<T>(_ claim: String, in dict: [String: Any]) throws -> T {
    guard let object = dict[claim] else { throw TokenError.missingClaim(claim) }
    guard let value = object as? T else { throw TokenError.invalidClaim(claim) }
    return value
}

// JWT Decoding

private func decodeEncodedFragment(_ string: String) throws -> Data {
    let length = 4 * ((string.count + 3) / 4)
    let base64 = string
        .replacingOccurrences(of: "_", with: "/")
        .replacingOccurrences(of: "-", with: "+")
        .padding(toLength: length, withPad: "=", startingAt: 0)
    guard let data = Data(base64Encoded: base64) else { throw TokenError.invalidEncoding }
    return data
}

private func decodeFragment(_ string: String) throws -> [String: Any] {
    let data = try decodeEncodedFragment(string)
    guard let json = try? JSONSerialization.jsonObject(with: data) else { throw TokenError.invalidData }
    guard let dict = json as? [String: Any] else { throw TokenError.invalidData }
    return dict
}

private func decodeJWT(_ jwt: String) throws -> [String: Any] {
    guard case let fragments = jwt.components(separatedBy: "."), fragments.count == 3 else { throw TokenError.invalidFormat }
    return try decodeFragment(fragments[1])
}
