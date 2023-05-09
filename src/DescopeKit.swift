
/// Provides functions for working with the Descope API.
///
/// This singleton object is provided as a convenience that should be suitable for usage
/// in most app architectures. If you prefer a different approach you can also create
/// an instance of the `DescopeSDK` class instead.
public enum Descope {
    /// The projectId of your Descope project.
    ///
    /// You will most likely want to set this value in your application's initialization code,
    /// and in most cases you only need to set this to work with the `Descope` singleton.
    ///
    /// - Note: This is a shortcut for setting the `Descope.config` property.
    public static var projectId: String {
        get { config.projectId }
        set { config = DescopeConfig(projectId: newValue) }
    }
    
    /// The configuration of the `Descope` singleton.
    ///
    /// Set this property instead of `projectId` in your application's initialization code
    /// if you require additional configuration.
    ///
    /// - Important: To prevent accidental misuse only one of `config` and `projectId` can
    ///     be set, and they can only be set once. If this isn't appropriate for your use
    ///     case you can also use the `DescopeSDK` class directly instead.
    public static var config: DescopeConfig = .initial {
        willSet {
            assert(config.projectId == "", "The config property must not be set more than once")
        }
    }
    
    /// Manages the storage and lifetime of a `DescopeSession`.
    ///
    /// You can use this `DescopeSessionManager` object as a shared instance to manage
    /// authenticated sessions in your application.
    ///
    ///     let authResponse = try await Descope.otp.verify(with: .email, loginId: "andy@example.com", code: "123456")
    ///     let session = DescopeSession(from: authResponse)
    ///     Descope.sessionManager.manageSession(session)
    ///
    /// See the documentation for `DescopeSessionManager` for more details.
    public static var sessionManager: DescopeSessionManager {
        get { sdk.sessionManager }
        set { sdk.sessionManager = newValue }
    }
}

/// Authentication functions that call the Descope API.
public extension Descope {
    /// General functions.
    static var auth: DescopeAuth { sdk.auth }
    
    /// Authentication with OTP codes via email or phone.
    static var otp: DescopeOTP { sdk.otp }
    
    /// Authentication with TOTP codes.
    static var totp: DescopeTOTP { sdk.totp }
    
    /// Authentication with magic links.
    static var magicLink: DescopeMagicLink { sdk.magicLink }
    
    /// Authentication with enchanted links.
    static var enchantedLink: DescopeEnchantedLink { sdk.enchantedLink }
    
    /// Authentication with OAuth.
    static var oauth: DescopeOAuth { sdk.oauth }
    
    /// Authentication with SSO.
    static var sso: DescopeSSO { sdk.sso }
    
    /// Authentication with passwords.
    static var password: DescopePassword { sdk.password }

    /// Exchanging access keys for session tokens.
    static var accessKey: DescopeAccessKey { sdk.accessKey }
    
    /// The underlying `DescopeSDK` object used by the `Descope` singleton.
    private static let sdk = DescopeSDK(config: config)
}

/// SDK information
public extension Descope {
    /// The Descope SDK name
    static let name = "DescopeKit"
    
    /// The Descope SDK version
    static let version = "0.9.1"
}
