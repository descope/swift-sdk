
import Foundation

/// The ``DescopeUser`` struct represents an existing user in Descope.
///
/// After a user is signed in with any authentication method the ``DescopeSession`` object
/// keeps a ``DescopeUser`` value in its `user` property so the user's details are always
/// available.
///
/// In the example below we finalize an OTP authentication for the user by verifying the
/// code. The authentication response has a `user` property which can be used
/// directly or later on when it's kept in the ``DescopeSession``.
///
///     let authResponse = try await Descope.otp.verify(with: .email, loginId: "andy@example.com", code: "123456")
///     print("Finished OTP login for user: \(authResponse.user)")
///
///     Descope.sessionManager.session = DescopeSession(from: authResponse)
///     print("Created session for user \(descopeSession.user.userId)")
///
/// The details for a signed in user can be updated manually by calling `auth.me` with
/// the `refreshJwt` from the active ``DescopeSession``. If the operation is successful the call
/// returns a new ``DescopeUser`` value.
///
///     guard let session = Descope.sessionManager.session else { return }
///     let descopeUser = try await Descope.auth.me(refreshJwt: session.refreshJwt)
///     session.update(with: descopeUser)
///
/// In the code above we check that there's an active ``DescopeSession`` in the shared
/// session manager. If so we ask the Descope server for the latest user details and
/// then update the ``DescopeSession`` with them.
public struct DescopeUser: Codable, Equatable {
    
    /// The unique identifier for the user in Descope.
    ///
    /// This value never changes after the user is created, and it always matches
    /// the `Subject` (`sub`) claim value in the user's JWT after signing in.
    public var userId: String
    
    /// The identifiers the user can sign in with.
    ///
    /// This is a list of one or more email addresses, phone numbers, usernames, or any
    /// custom identifiers the user can authenticate with.
    public var loginIds: [String]
    
    /// The time at which the user was created in Descope.
    public var createdAt: Date
    
    /// The user's full name.
    public var name: String?
    
    /// The user's profile picture.
    public var picture: URL?
    
    /// The user's email address.
    ///
    /// If this is non-nil and the ``isVerifiedEmail`` flag is `true` then this email address
    /// can be used to do email based authentications such as magic link, OTP, etc.
    public var email: String?
    
    /// Whether the email address has been verified to be a valid authentication method
    /// for this user. If ``email`` is `nil` then this is always `false`.
    public var isVerifiedEmail: Bool
    
    /// The user's phone number.
    ///
    /// If this is non-nil and the ``isVerifiedPhone`` flag is `true` then this phone number
    /// can be used to do phone based authentications such as OTP.
    public var phone: String?
    
    /// Whether the phone number has been verified to be a valid authentication method
    /// for this user. If ``phone`` is `nil` then this is always `false`.
    public var isVerifiedPhone: Bool
    
    /// The user's given name.
    public var givenName: String?
    
    /// The user's middle name.
    public var middleName: String?
    
    /// The user's family name.
    public var familyName: String?
    
    /// A mapping of any custom attributes associated with this user.
    /// User custom attributes are managed via the Descope console.
    public var customAttributes: [String: Any]
    
    public init(userId: String, loginIds: [String], createdAt: Date, name: String? = nil, picture: URL? = nil, email: String? = nil, isVerifiedEmail: Bool = false, phone: String? = nil, isVerifiedPhone: Bool = false, givenName: String? = nil, middleName: String? = nil, familyName: String? = nil, customAttributes: [String: Any] = [:]) {
        self.userId = userId
        self.loginIds = loginIds
        self.createdAt = createdAt
        self.name = name
        self.picture = picture
        self.email = email
        self.isVerifiedEmail = isVerifiedEmail
        self.phone = phone
        self.isVerifiedPhone = isVerifiedPhone
        self.givenName = givenName
        self.middleName = middleName
        self.familyName = familyName
        self.customAttributes = customAttributes
    }
    
    enum CodingKeys: CodingKey {
        case userId
        case loginIds
        case createdAt
        case name
        case picture
        case email
        case isVerifiedEmail
        case phone
        case isVerifiedPhone
        case givenName
        case middleName
        case familyName
        case customAttributes
    }
    
    public init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        userId = try values.decode(String.self, forKey: .userId)
        loginIds = try values.decode(Array<String>.self, forKey: .loginIds)
        createdAt = try values.decode(Date.self, forKey: .createdAt)
        name = try values.decode(String?.self, forKey: .name)
        picture = try values.decode(URL?.self, forKey: .picture)
        email = try values.decode(String?.self, forKey: .email)
        isVerifiedEmail = try values.decode(Bool.self, forKey: .isVerifiedEmail)
        phone = try values.decode(String?.self, forKey: .phone)
        isVerifiedPhone = try values.decode(Bool.self, forKey: .isVerifiedPhone)
        givenName = try values.decode(String?.self, forKey: .givenName)
        middleName = try values.decode(String?.self, forKey: .middleName)
        familyName = try values.decode(String?.self, forKey: .familyName)
        let value = try values.nestedContainer(keyedBy: JSONCodingKeys.self, forKey: .customAttributes)
        customAttributes = decodeJson(container: value)
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(userId, forKey: .userId)
        try container.encode(loginIds, forKey: .loginIds)
        try container.encode(createdAt, forKey: .createdAt)
        try container.encode(name, forKey: .name)
        try container.encode(picture, forKey: .picture)
        try container.encode(email, forKey: .email)
        try container.encode(isVerifiedEmail, forKey: .isVerifiedEmail)
        try container.encode(phone, forKey: .phone)
        try container.encode(isVerifiedPhone, forKey: .isVerifiedPhone)
        try container.encode(givenName, forKey: .givenName)
        try container.encode(middleName, forKey: .middleName)
        try container.encode(familyName, forKey: .familyName)
        var nestedContainer = container.nestedContainer(keyedBy: JSONCodingKeys.self, forKey: .customAttributes)
        try customAttributes.encodeJson(container: &nestedContainer)
    }
    
    public static func == (lhs: DescopeUser, rhs: DescopeUser) -> Bool {
        return lhs.userId == rhs.userId &&
        lhs.loginIds == rhs.loginIds &&
        lhs.createdAt == rhs.createdAt &&
        lhs.name == rhs.name &&
        lhs.picture == rhs.picture &&
        lhs.email == rhs.email &&
        lhs.isVerifiedEmail == rhs.isVerifiedEmail &&
        lhs.phone == rhs.phone &&
        lhs.isVerifiedPhone == rhs.isVerifiedPhone &&
        lhs.givenName == rhs.givenName &&
        lhs.middleName == rhs.middleName &&
        lhs.familyName == rhs.familyName
        // lhs.customAttributes == rhs.customAttributes
    }
}

extension DescopeUser: CustomStringConvertible {
    /// Returns a textual representation of this ``DescopeUser`` object.
    ///
    /// It returns a string with the user's unique id, login id, and name.
    public var description: String {
        var extras = ""
        if let loginId = loginIds.first {
            extras += ", loginId: \"\(loginId)\""
        }
        if let name {
            extras += ", name: \"\(name)\""
        }
        return "DescopeUser(id: \"\(userId)\"\(extras))"
    }
}
