
import Foundation

public enum DeliveryMethod {
    case whatsapp, sms, email
}

public struct User {
    public var name: String?
    public var phone: String?
    public var email: String?
    
    public static let empty = User()
}

public struct MeResponse {
    public var userId: String
    public var externalIds: [String]
    public var name: String?
    public var email: (value: String, isVerified: Bool)?
    public var phone: (value: String, isVerified: Bool)?
}
