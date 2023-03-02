
/// Provides functions for working with Descope API.
///
/// This singleton object is provided as a convenience that should be suitable for
/// usage in most app architectures. If you prefer a different approach you can also
/// create an instance of the `DescopeSDK` class instead.
public enum Descope {
    
    /// The Descope SDK name
    public static let name = "DescopeKit"
    
    /// The Descope SDK version
    public static let version = "0.9.0"
    
    /// The projectId of your Descope project.
    ///
    /// You will most likely want to set this value during your application's
    /// initialization flow, and in most cases you only need to set this to
    /// work with the SDK.
    ///
    /// - Note: This is a shortcut for setting the `Descope.config` property.
    ///     To prevent accidental misuse only one of these properties can be set,
    ///     and they can only be set once. If this isn't appropriate for your usage
    ///     scenario you can also use the `DescopeSDK` class directly instead.
    public static var projectId: String {
        get {
            return config.projectId
        }
        set {
            precondition(config.projectId == "", "ProjectId should not be set more than once")
            config = DescopeConfig(projectId: newValue)
        }
    }
    
    /// The configuration of the Descope SDK.
    ///
    /// Set this property instead of `projectId` during your application's
    /// initialization flow if you require additional configuration.
    public static var config: DescopeConfig = .initial {
        willSet {
            precondition(config.projectId == "", "Config should not be set more than once")
        }
        didSet {
            precondition(config.projectId != "", "Config should not be an empty string")
        }
    }
    
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

    /// Internal SDK object
    static let sdk = DescopeSDK(config: config)
}
