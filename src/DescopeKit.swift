
/// Provides functions for working with the Descope API.
///
/// This singleton object is provided as a simple way to access the Descope SDK from anywhere
/// in your code. It should be suitable for most app architectures, but if you prefer a different
/// approach you can also create an instance of the ``DescopeSDK`` class instead and pass it
/// to wherever it's needed.
public enum Descope {
    /// The projectId of your Descope project.
    ///
    /// You will most likely want to set this value in your application's initialization code,
    /// and in most cases you only need to set this to work with the ``Descope`` singleton.
    ///
    /// - Note: This is a shortcut for setting the `Descope.config` property.
    public static var projectId: String {
        get { config.projectId }
        set { config = DescopeConfig(projectId: newValue) }
    }
    
    /// The configuration of the ``Descope`` singleton.
    ///
    /// Set this property instead of `projectId` in your application's initialization code
    /// if you require additional configuration.
    ///
    /// - Important: To prevent accidental misuse only one of `config` and `projectId` can
    ///     be set, and they can only be set once. If this isn't appropriate for your use
    ///     case you can also use the ``DescopeSDK`` class directly instead.
    public static var config: DescopeConfig = .initial {
        willSet {
            assert(config.projectId == "", "The config property must not be set more than once")
        }
    }
    
    /// Manages the storage and lifetime of a ``DescopeSession``.
    ///
    /// You can use this ``DescopeSessionManager`` object as a shared instance to manage
    /// authenticated sessions in your application.
    /// 
    ///     let authResponse = try await Descope.otp.verify(with: .email, loginId: "andy@example.com", code: "123456")
    ///     let session = DescopeSession(from: authResponse)
    ///     Descope.sessionManager.manageSession(session)
    ///
    /// See the documentation for ``DescopeSessionManager`` for more details.
    public static var sessionManager: DescopeSessionManager {
        get { sdk.sessionManager }
        set { sdk.sessionManager = newValue }
    }
}

/// Authentication functions that call the Descope API.
public extension Descope {
    /// Provides functions for managing authenticated sessions.
    static var auth: DescopeAuth { sdk.auth }
    
    /// Provides functions for authentication with OTP codes via email or phone.
    static var otp: DescopeOTP { sdk.otp }
    
    /// Provides functions for authentication with TOTP codes.
    static var totp: DescopeTOTP { sdk.totp }
    
    /// Provides functions for authentication with magic links.
    static var magicLink: DescopeMagicLink { sdk.magicLink }
    
    /// Provides functions for authentication with enchanted links.
    static var enchantedLink: DescopeEnchantedLink { sdk.enchantedLink }
    
    /// Provides functions for authentication with OAuth.
    static var oauth: DescopeOAuth { sdk.oauth }
    
    /// Provides functions for authentication with SSO.
    static var sso: DescopeSSO { sdk.sso }
    
    /// Provides functions for authentication with passwords.
    static var password: DescopePassword { sdk.password }

    /// Provides functions for authentication using flows.
    static var flow: DescopeFlow { sdk.flow }
    
    /// Provides functions for exchanging access keys for session tokens.
    static var accessKey: DescopeAccessKey { sdk.accessKey }
    
    /// The underlying ``DescopeSDK`` object used by the ``Descope`` singleton.
    private static let sdk = DescopeSDK(config: config)
}
