
public class DescopeSDK {
    public let config: DescopeConfig
    
    public let auth: DescopeAuth
    public let accessKey: DescopeAccessKey
    public let otp: DescopeOTP
    public let totp: DescopeTOTP
    public let password: DescopePassword
    public let magicLink: DescopeMagicLink
    public let enchantedLink: DescopeEnchantedLink
    public let oauth: DescopeOAuth
    public let sso: DescopeSSO

    public convenience init(projectId: String) {
        self.init(config: DescopeConfig(projectId: projectId))
    }
    
    public convenience init(config: DescopeConfig) {
        let client = DescopeClient(config: config)
        self.init(config: config, client: client)
    }
    
    init(config: DescopeConfig, client: DescopeClient) {
        precondition(config.projectId != "", "ProjectId should not be an empty string")
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
    }
}

// Description

extension DescopeSDK: CustomStringConvertible {
    public var description: String {
        return "DescopeSDK(project: \"\(config.projectId)\")"
    }
}
