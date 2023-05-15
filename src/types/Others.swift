
import Foundation
#if os(iOS)
import UIKit
#endif

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
public struct SignUpDetails {
    public var name: String?
    public var email: String?
    public var phone: String?
    
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
    
    /// When updating a user with the ``addToLoginIds`` option, if another user already
    /// has the same email address or phone number as a `loginId` the two users are
    /// merged and one of them is deleted.
    ///
    /// By default, the other user's details are merged into the current user and the
    /// other user is then deleted. In other words, the user who the `refreshJwt` belongs
    /// to is kept.
    ///
    /// If this option is set however then the current user is merged into the other
    /// user, and the current user is discarded. In this case the `refreshJwt` and its
    /// ``DescopeSession`` will no longer be valid, and a new ``DescopeSession`` is
    /// returned for the other user instead.
    public static let onMergeUseExisting = UpdateOptions(rawValue: 2)
    
    public let rawValue: Int
    
    public init(rawValue: Int) {
        self.rawValue = rawValue
    }
}
