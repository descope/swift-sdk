
import Foundation

public class DescopeSDK {
    public let config: DescopeConfig
    
    public lazy var auth: DescopeAuth = Auth(config: config)

    init() {
        self.config = .empty
    }
    
    public init(config: DescopeConfig) {
        self.config = config
    }
}

public struct DescopeConfig {
    public var projectId: String
    public var baseURL: String = "https://api.descope.com"
    
    init(projectId: String, baseURL: String? = nil) {
        self.projectId = projectId
        self.baseURL = baseURL ?? self.baseURL
    }
    
    static public let empty = DescopeConfig(projectId: "")
}
