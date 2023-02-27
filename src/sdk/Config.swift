
public struct DescopeConfig {
    public var projectId: String
    public var baseURL: String = "https://api.descope.com"
    
    public init(projectId: String) {
        self.projectId = projectId
    }
    
    public init(projectId: String, baseURL: String) {
        self.projectId = projectId
        self.baseURL = baseURL
    }
}
