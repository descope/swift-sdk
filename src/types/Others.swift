
import Foundation
#if os(iOS)
import UIKit
#endif

// Requests

/// The delivery method for an OTP or Magic Link message.
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

/// Used to provide additional details about a user in sign up calls.
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

/// Used to configure how user details are updated.
public struct UpdateOptions: OptionSet {
    
    /// When updating a user's email address or phone number if this option is set
    /// the new value will be added to the user's list of `loginIds`.
    public static let addToLoginIds = UpdateOptions(rawValue: 1)
    
    /// When updating a user with the `addToLoginIds` option, if another user already
    /// has the same email address or phone number as a `loginId` the two users are
    /// merged and one of them is deleted.
    ///
    /// By default, the other user's details are merged into the current user and the
    /// other user is then deleted. In other words, the user who the `refreshJwt` belongs
    /// to is kept.
    ///
    /// If this option is set however then the current user is merged into the other
    /// user, and the current user is discarded. In this case the `refreshJwt` and its
    /// `DescopeSession` will no longer be valid, and a new `DescopeSession` is returned
    /// for the other user instead.
    public static let onMergeUseExisting = UpdateOptions(rawValue: 2)
    
    public let rawValue: Int
    public init(rawValue: Int) {
        self.rawValue = rawValue
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
    public var createdAt: Date
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

/// Represents the rules for valid passwords.
///
/// The policy is configured in the password settings in the Descope console, and
/// these values can be used to implement client-side validation of new user passwords
/// for a better user experience.
///
/// In any case, all password rules are enforced by Descope on the server side as well.
public struct PasswordPolicy {
    public var minLength: Int
    public var lowercase: Bool
    public var uppercase: Bool
    public var number: Bool
    public var nonAlphanumeric: Bool
}
