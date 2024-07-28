import Foundation

class DescopeContentClient: HTTPClient {
    let config: DescopeConfig
    
    init(config: DescopeConfig, baseURL: String) {
        self.config = config
        let baseContentURL = contentURL(from: baseURL)
        super.init(baseURL: baseContentURL, logger: config.logger, networkClient: config.networkClient)
    }
    
    // MARK: - Config
    
    struct ConfigResponse: JSONResponse {
        var componentsVersion: String
        var flows: [String: FlowConfig]
    }
    
    struct FlowConfig: JSONResponse {
        var version: Int
    }
    
    func flowConfig() async throws -> ConfigResponse {
        //https://static.descope.com/pages/P2YQt31cXxGZeZAwKWyqzTaQa1dt/v2-beta/config.json
        return try await get("pages/\(config.projectId)/v2-beta/config.json")
    }
    
    // MARK: - Internal
    
    override func errorForResponseData(_ data: Data) -> Error? {
        return DescopeError(errorResponse: data)
    }
    
}

func contentURL(from baseURL: String) -> String {
    if (baseURL.contains(".descope.org") || baseURL.contains(".descope.team")) {
        return "https://static.descope.org"
    } else if (baseURL.contains(".descope.com")) {
        return "https://static.descope.com"
    }
    return baseURL
}
