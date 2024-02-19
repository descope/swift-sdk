
import Foundation

public extension DescopeOTP {
    @available(*, deprecated, message: "Pass a value (or an empty array) for the options parameter")
    func signIn(with method: DeliveryMethod, loginId: String) async throws -> String {
        return try await signIn(with: method, loginId: loginId, options: [])
    }
    
    @available(*, deprecated, message: "Pass a value (or an empty array) for the options parameter")
    func signUpOrIn(with method: DeliveryMethod, loginId: String) async throws -> String {
        return try await signUpOrIn(with: method, loginId: loginId, options: [])
    }
}

public extension DescopeTOTP {
    @available(*, deprecated, message: "Pass a value (or an empty array) for the options parameter")
    func verify(loginId: String, code: String) async throws -> AuthenticationResponse {
        return try await verify(loginId: loginId, code: code, options: [])
    }
}

public extension DescopeMagicLink {
    @available(*, deprecated, message: "Pass a value (or an empty array) for the options parameter")
    func signIn(with method: DeliveryMethod, loginId: String, redirectURL: String?) async throws -> String {
        return try await signIn(with: method, loginId: loginId, redirectURL: redirectURL, options: [])
    }
    
    @available(*, deprecated, message: "Pass a value (or an empty array) for the options parameter")
    func signUpOrIn(with method: DeliveryMethod, loginId: String, redirectURL: String?) async throws -> String {
        return try await signUpOrIn(with: method, loginId: loginId, redirectURL: redirectURL, options: [])
    }
}

public extension DescopeEnchantedLink {
    @available(*, deprecated, message: "Pass a value (or an empty array) for the options parameter")
    func signIn(loginId: String, redirectURL: String?) async throws -> EnchantedLinkResponse {
        return try await signIn(loginId: loginId, redirectURL: redirectURL, options: [])
    }
    
    @available(*, deprecated, message: "Pass a value (or an empty array) for the options parameter")
    func signUpOrIn(loginId: String, redirectURL: String?) async throws -> EnchantedLinkResponse {
        return try await signUpOrIn(loginId: loginId, redirectURL: redirectURL, options: [])
    }
}

public extension DescopeOAuth {
    @available(*, deprecated, message: "Pass a value (or an empty array) for the options parameter")
    func start(provider: OAuthProvider, redirectURL: String?) async throws -> URL {
        return try await start(provider: provider, redirectURL: redirectURL, options: [])
    }
}

public extension DescopeSSO {
    @available(*, deprecated, message: "Pass a value (or an empty array) for the options parameter")
    func start(emailOrTenantName: String, redirectURL: String?) async throws -> URL {
        return try await start(emailOrTenantName: emailOrTenantName, redirectURL: redirectURL, options: [])
    }
}

public extension DescopeSDK {
    @available(*, deprecated, message: "Use the DescopeSDK.init(projectId:with:) initializer instead")
    convenience init(config: DescopeConfig) {
        self.init(projectId: config.projectId, with: { $0 = config })
    }
}

public extension Descope {
    static var projectId: String {
        @available(*, deprecated, message: "Use Descope.config.projectId instead")
        get { Descope.sdk.config.projectId }
        @available(*, deprecated, message: "Use the setup() function to initialize the Descope singleton")
        set { Descope.sdk = DescopeSDK(projectId: newValue) }
    }

    static var config: DescopeConfig {
        get { Descope.sdk.config }
        @available(*, deprecated, message: "Use the setup() function to initialize the Descope singleton")
        set { Descope.sdk = DescopeSDK(projectId: newValue.projectId, with: { $0 = newValue }) }
    }
}

public extension DescopeConfig {
    @available(*, deprecated, message: "Use the Descope.setup() function or DescopeSDK.init(projectId:with:) initializer instead")
    init(projectId: String, baseURL: String? = nil, logger: DescopeLogger? = nil) {
        self.projectId = projectId
        self.baseURL = baseURL
        self.logger = logger
    }
}
