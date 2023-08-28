
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

/// Used to configure how users are updated.
public struct UpdateOptions: OptionSet {
    /// Whether to allow sign in from a new `loginId` after an update.
    ///
    /// When a user's email address or phone number are updated and this option is set
    /// the new value is added to the user's list of `loginIds`, and the user from that
    /// point on will be able to use it to sign in.
    public static let addToLoginIds = UpdateOptions(rawValue: 1)
    
    /// Whether to keep or delete the current user when merging two users after an update.
    ///
    /// When updating a user's email address or phone number with the ``addToUserLoginIds``
    /// option set, if another user in the the system already has the same email address
    /// or phone number as the one being added in their list of `loginIds` the two users
    /// are merged and one of them is deleted.
    ///
    /// This scenario can happen when a user uses multiple authentication methods
    /// and ends up with multiple accounts. For example, a user might sign in with
    /// their email address at first. Then at some point later they reinstall the
    /// app and use OAuth to authenticate, and a new user account is created. If
    /// the user then updates their account and adds their email address the
    /// two accounts need to be merged.
    ///
    /// Let's define the "updated user" to be the user being updated and whom
    /// the `refreshJwt` belongs to, and the "existing user" to be another user in
    /// the system with the same `loginId`.
    ///
    /// By default, the updated user is kept, the existing user's details are merged
    /// into the updated user, and the existing user is then deleted.
    ///
    /// If this option is set however then the current user is merged into the existing
    /// user, and the current user is deleted. In this case the ``DescopeSession`` and
    /// its `refreshJwt` that was used to initiate the update operation will no longer
    /// be valid, and an ``AuthenticationResponse`` is returned for the existing user
    /// instead.
    public static let onMergeUseExisting = UpdateOptions(rawValue: 2)
    
    public let rawValue: Int
    
    public init(rawValue: Int) {
        self.rawValue = rawValue
    }
}
