
import Foundation
#if os(iOS)
import UIKit
#endif

// Enums

public enum DeliveryMethod: String {
    case whatsapp
    case sms
    case email
}

public enum OAuthProvider: String {
    case facebook
    case github
    case google
    case microsoft
    case gitlab
    case apple
}

// Structs

public struct User {
    public var name: String?
    public var phone: String?
    public var email: String?
    
    public init(name: String? = nil, phone: String? = nil, email: String? = nil) {
        self.name = name
        self.phone = phone
        self.email = email
    }
}

// Responses

public struct MeResponse {
    public var userId: String
    public var loginIds: [String]
    public var name: String?
    public var picture: String?
    public var email: (value: String, isVerified: Bool)?
    public var phone: (value: String, isVerified: Bool)?
}

public struct EnchantedLinkResponse {
    public var linkId: String
    public var pendingRef: String
}

public struct TOTPResponse {
    public var provisioningURL: String
    #if os(iOS)
    public var image: UIImage
    #else
    public var image: Data
    #endif
    public var key: String
}
