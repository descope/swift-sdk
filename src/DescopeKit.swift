
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
    
    public init(projectId: String) {
        self.projectId = projectId
    }
    
    static public let empty = DescopeConfig(projectId: "")
}
