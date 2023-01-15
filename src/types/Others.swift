
public enum DeliveryMethod: String {
    case whatsapp
    case sms
    case email
}

public struct User {
    public var name: String?
    public var phone: String?
    public var email: String?
}

public struct MeResponse {
    public var userId: String
    public var loginIds: [String]
    public var name: String?
    public var picture: String?
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
