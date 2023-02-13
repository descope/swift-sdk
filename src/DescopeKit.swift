
/// Provides functions for working with Descope API.
public enum Descope {
    
    /// The Descope SDK name
    public static let name = "DescopeKit"
    
    /// The Descope SDK version
    public static let version = "1.0.0"
    
    /// The project ID of your Descope project. You will most likely want to set this
    /// value during your application's initialization flow.
    public static var projectId: String = "" {
        willSet {
            precondition(projectId == "", "ProjectId should not be set more than once")
        }
        didSet {
            precondition(projectId != "", "ProjectId should not be an empty string")
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
    
    /// Authentication with magic links
    public static var magicLink: DescopeMagicLink { sdk.magicLink }
    
    /// Authentication with enchanted links
    public static var enchantedLink: DescopeEnchantedLink { sdk.enchantedLink }
    
    /// Authentication with OAuth
    public static var oauth: DescopeOAuth { sdk.oauth }
    
    /// Authentication with SSO
    public static var sso: DescopeSSO { sdk.sso }

    /// Internal SDK object
    static let sdk = DescopeSDK(projectId: projectId)
}
