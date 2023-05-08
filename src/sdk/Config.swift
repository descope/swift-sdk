
/// The configuration of the Descope SDK.
public struct DescopeConfig {
    /// The id of the Descope project.
    public var projectId: String
    
    /// The base URL of the Descope server.
    public var baseURL: String = "https://api.descope.com"

    /// Creates a new `DescopeConfig` object.
    ///
    /// - Parameters:
    ///   - projectId: The id of the Descope project can be found in the
    ///     project page in the Descope console.
    ///   - baseURL: An optional override for the URL of the Descope server,
    ///     in case it needs to be accessed through a CNAME record.
    public init(projectId: String, baseURL: String? = nil) {
        self.projectId = projectId
        if let baseURL {
            self.baseURL = baseURL
        }
    }
}

// Internal

extension DescopeConfig {
    static let initial = DescopeConfig(projectId: "")
}
