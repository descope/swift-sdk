
/// Provides functions for working with the Descope API.
///
/// This singleton object is provided as a convenience that should be suitable for usage
/// in most app architectures. If you prefer a different approach you can also create
/// an instance of the `DescopeSDK` class instead.
public enum Descope {
    
    /// The Descope SDK name
    public static let name = "DescopeKit"
    
    /// The Descope SDK version
    public static let version = "0.9.1"

    
    // MARK: Initialization
    
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
    
    
    // MARK: Session Management
    
    public static var sessionManager: DescopeSessionManager {
        get { sdk.sessionManager }
        set { sdk.sessionManager = newValue }
    }
    
    
    // MARK: SDK Routes
    
    /// General functions
    public static var auth: DescopeAuth { sdk.auth }
    
    /// Authentication with access keys
    public static var accessKey: DescopeAccessKey { sdk.accessKey }
    
    /// Authentication with one time codes
    public static var otp: DescopeOTP { sdk.otp }
    
    /// Authentication with TOTP
    public static var totp: DescopeTOTP { sdk.totp }
    
    /// Authentication with passwords
    public static var password: DescopePassword { sdk.password }

    /// Authentication with magic links
    public static var magicLink: DescopeMagicLink { sdk.magicLink }
    
    /// Authentication with enchanted links
    public static var enchantedLink: DescopeEnchantedLink { sdk.enchantedLink }
    
    /// Authentication with OAuth
    public static var oauth: DescopeOAuth { sdk.oauth }
    
    /// Authentication with SSO
    public static var sso: DescopeSSO { sdk.sso }
    
    
    // MARK: Internal

    /// The underlying `DescopeSDK` object used by the `Descope` singleton.
    private static let sdk = DescopeSDK(config: config)
}
