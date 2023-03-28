
import Foundation
#if os(iOS)
import UIKit
#endif

// Enums

/// The delivery method for an OTP message.
public enum DeliveryMethod: String {
    case whatsapp
    case sms
    case email
}

/// The provider to use in an OAuth flow.
public enum OAuthProvider: String {
    case facebook
    case github
    case google
    case microsoft
    case gitlab
    case apple
}

// Structs

/// Used to provide additional details about a user during in sign up calls.`
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

/// Returned from the me call.
///
/// The `userId` field is the unique identifier for the user in Descope, and it
/// matches the `Subject` (`sub`) value in the user's JWT after logging in. The
/// `loginIds` is the set of acceptable login identifiers for the user, e.g.,
/// email addresses, phone numbers, usernames, etc.
public struct MeResponse {
    public var userId: String
    public var loginIds: [String]
    public var name: String?
    public var picture: String?
    public var email: (value: String, isVerified: Bool)?
    public var phone: (value: String, isVerified: Bool)?
}

/// Returned from calls that start an enchanted link flow.
///
/// The `linkId` value needs to be displayed to the user so they know which
/// link should be clicked on in the enchanted link email. The `maskedEmail`
/// field can also be shown to inform the user to which address the email
/// was sent. The `pendingRef` field is used to poll the server for the
/// enchanted link flow result.
public struct EnchantedLinkResponse {
    public var linkId: String
    public var pendingRef: String
    public var maskedEmail: String
}

/// Returned from TOTP calls that create a new seed.
///
/// The `provisioningURL` field wraps the key (seed) in a URL that can be
/// opened by authenticator apps. The `image` field encodes the key (seed)
/// in a QR code image.
public struct TOTPResponse {
    public var provisioningURL: String
    #if os(iOS)
    public var image: UIImage
    #else
    public var image: Data
    #endif
    public var key: String
}

/// Represents the rules for valid passwords configured in the policy in the
/// Descope console.
///
/// This can be used to implement client-side validation of new
/// user passwords for a better user experience. Either way, the comprehensive
/// policy is always enforced by Descope on the server side.
public struct PasswordPolicy {
    public var minLength: Int
    public var lowercase: Bool
    public var uppercase: Bool
    public var number: Bool
    public var nonAlphanumeric: Bool
}
