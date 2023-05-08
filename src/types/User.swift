
import Foundation

/// Returned from the me call.
///
/// The `userId` field is the unique identifier for the user in Descope, and it
/// matches the `Subject` (`sub`) value in the user's JWT after logging in. The
/// `loginIds` is the set of acceptable login identifiers for the user, e.g.,
/// email addresses, phone numbers, usernames, etc.
public struct DescopeUser: Codable {
    
    public var userId: String
    
    public var loginIds: [String]
    
    public var createdAt: Date
    
    public var name: String?
    
    public var picture: String?
    
    public var email: String?
    
    public var isVerifiedEmail: Bool
    
    public var phone: String?
    
    public var isVerifiedPhone: Bool
}
