
public enum DeliveryMethod: String {
    case whatsapp
    case sms
    case email
}

public struct User {
    public var name: String?
    public var phone: String?
    public var email: String?
    //public var displayName: String?
    public init(name: String = "", phone: String = "",
                email: String = "") {
        self.name = name
        self.phone = phone
        self.email = email
        //self.displayName = displayName
      }
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
    public var image: String
    public var key: String
}

public struct EnchantedLinkResponse {
    public var linkId: String
    public var pendingRef: String
}

public enum OAuthProvider: String {
    case facebook
    case github
    case google
    case microsoft
    case gitlab
    case apple
}
