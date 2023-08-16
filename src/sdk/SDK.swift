
/// Provides functions for working with the Descope API.
///
/// The ``Descope`` singleton object exposes the same properties as the ``DescopeSDK`` class,
/// and in most app architectures it might be more convenient to use it instead.
public class DescopeSDK {
    /// The configuration of the ``DescopeSDK`` instance.
    public let config: DescopeConfig
    
    /// Provides functions for managing authenticated sessions.
    public let auth: DescopeAuth
    
    /// Provides functions for authentication with OTP codes via email or phone.
    public let otp: DescopeOTP
    
    /// Provides functions for authentication with TOTP codes.
    public let totp: DescopeTOTP
    
    /// Provides functions for authentication with magic links.
    public let magicLink: DescopeMagicLink
    
    /// Provides functions for authentication with enchanted links.
    public let enchantedLink: DescopeEnchantedLink
    
    /// Provides functions for authentication with OAuth.
    public let oauth: DescopeOAuth
    
    /// Provides functions for authentication with SSO.
    public let sso: DescopeSSO
    
    /// Provides functions for authentication with passwords.
    public let password: DescopePassword
    
    /// Provides functions for authentication using flows.
    public let flow: DescopeFlow

    /// Provides functions for exchanging access keys for session tokens.
    public let accessKey: DescopeAccessKey

    /// Manages the storage and lifetime of a ``DescopeSession``.
    ///
    /// You can use this ``DescopeSessionManager`` object to manage authenticated sessions
    /// in your application whereever you pass this ``DescopeSDK`` instance.
    ///
    ///     class ViewController: UIViewController {
    ///         let descope: DescopeSDK
    ///
    ///         init(descope: DescopeSDK) {
    ///             self.descope = descope
    ///         }
    ///
    ///         func verifyOTP(phone: String, code: String) async throws {
    ///             let authResponse = try await descope.otp.verify(with: .sms, loginId: phone, code: code)
    ///             let session = DescopeSession(from: authResponse)
    ///             descope.sessionManager.manageSession(session)
    ///         }
    ///
    /// See the documentation for ``DescopeSessionManager`` for more details.
    ///
    /// - Note: You can set your own instance of ``DescopeSessionManager`` directly after
    ///     creating a ``DescopeSDK`` object. Since the initial value of ``sessionManager``
    ///     is created lazily this will ensure that the default instance doesn't get a
    ///     chance to perform any keychain queries before being replaced.
    public lazy var sessionManager: DescopeSessionManager = DescopeSessionManager(sdk: self)
    
    /// Creates a new ``DescopeSDK`` object.
    ///
    /// - Parameter projectId: The id of the Descope project can be found
    ///     in the project page in the Descope console.
    ///
    /// - Note: This is a shortcut for calling the ``init(config:)`` initializer.
    public convenience init(projectId: String) {
        self.init(config: DescopeConfig(projectId: projectId))
    }
    
    /// Creates a new ``DescopeSDK`` object.
    ///
    /// - Parameter config: The configuration of the ``DescopeSDK`` instance.
    public convenience init(config: DescopeConfig) {
        let client = DescopeClient(config: config)
        self.init(config: config, client: client)
    }
    
    private init(config: DescopeConfig, client: DescopeClient) {
        assert(config.projectId != "", "The projectId value must not be an empty string")
        self.config = config
        self.auth = Auth(client: client)
        self.accessKey = AccessKey(client: client)
        self.otp = OTP(client: client)
        self.totp = TOTP(client: client)
        self.password = Password(client: client)
        self.magicLink = MagicLink(client: client)
        self.enchantedLink = EnchantedLink(client: client)
        self.oauth = OAuth(client: client)
        self.sso = SSO(client: client)
        self.flow = Flow(client: client)
    }
}

/// SDK information
public extension DescopeSDK {
    /// The Descope SDK name
    static let name = "DescopeKit"
    
    /// The Descope SDK version
    static let version = "0.9.1"
}

// Internal

private extension DescopeSessionManager {
    convenience init(sdk: DescopeSDK) {
        let storage = SessionStorage(projectId: sdk.config.projectId)
        let lifecycle = SessionLifecycle(auth: sdk.auth)
        self.init(storage: storage, lifecycle: lifecycle)
    }
}
