
import Foundation

public protocol DescopeToken {
    var jwt: String { get }
    var id: String { get }
    var projectId: String { get }
    var expiresAt: Date? { get }
    var isExpired: Bool { get }
    var claims: [String: Any] { get }
    func permissions(forTenant tenant: String?) -> [String]
    func roles(forTenant tenant: String?) -> [String]
}

public enum DeliveryMethod: String {
    case whatsapp, sms, email
}

public struct User {
    public var name: String?
    public var phone: String?
    public var email: String?
}

public struct MeResponse {
    public var userId: String
    public var externalIds: [String]
    public var name: String?
    public var email: (value: String, isVerified: Bool)?
    public var phone: (value: String, isVerified: Bool)?
}

public struct TOTPResponse {
    public var provisioningURL: String
    public var key: String
}

public enum OAuthProvider: String {
    case facebook
    case github
    case google
    case microsoft
    case gitlab
    case apple
}
