
import Foundation

class HttpClient {
    let baseURL: String
    let session: URLSession
    
    init(baseURL: String, session: URLSession? = nil) {
        self.baseURL = baseURL
        self.session = session ?? makeURLSession()
    }
    
    deinit {
        session.finishTasksAndInvalidate()
    }
    
    /// Convenience response functions

    final func get<T: Decodable>(_ route: String, headers: [String: String] = [:], params: [String: String?] = [:]) async throws -> T {
        let data = try await get(route, headers: headers, params: params)
        return try JSONDecoder().decode(T.self, from: data)
    }
    
    final func post<T: Decodable>(_ route: String, headers: [String: String] = [:], params: [String: String?] = [:], body: [String: Any?] = [:]) async throws -> T {
        let data = try await post(route, headers: headers, params: params, body: body)
        return try JSONDecoder().decode(T.self, from: data)
    }
    
    /// Convenience data functions
    
    @discardableResult
    final func get(_ route: String, headers: [String: String] = [:], params: [String: String?] = [:]) async throws -> Data {
        return try await call(route, method: "GET", headers: headers, params: params, body: nil)
    }
    
    @discardableResult
    final func post(_ route: String, headers: [String: String] = [:], params: [String: String?] = [:], body: [String: Any?] = [:]) async throws -> Data {
        let data = try JSONSerialization.data(withJSONObject: body.compacted(), options: [])
        return try await call(route, method: "POST", headers: headers, params: params, body: data)
    }
    
    /// Override points
    
    var basePath: String {
        return "/"
    }
    
    var defaultHeaders: [String: String] {
        return [:]
    }
    
    var defaultTimeout: TimeInterval {
        return 15
    }
    
    func errorForResponseData(_ data: Data) -> Error? {
        return nil
    }
    
    /// Private
    
    private func call(_ route: String, method: String, headers: [String: String], params: [String: String?], body: Data?) async throws -> Data {
        let request = try makeRequest(route: route, method: method, headers: headers, params: params, body: body)
        let (data, response) = try await sendRequest(request)
        guard let response = response as? HTTPURLResponse else { throw DescopeError(clientError: .invalidResponse) }
        if let error = DescopeError.from(statusCode: response.statusCode) {
            throw errorForResponseData(data) ?? error
        }
        return data
    }
    
    private func makeRequest(route: String, method: String, headers: [String: String], params: [String: String?], body: Data?) throws -> URLRequest {
        let url = try makeURL(route: route, params: params)
        var request = URLRequest(url: url, cachePolicy: .reloadIgnoringLocalAndRemoteCacheData, timeoutInterval: defaultTimeout)
        request.httpMethod = method
        request.httpBody = body
        for (key, value) in mergeHeaders(headers, with: defaultHeaders, for: request) {
            request.setValue(value, forHTTPHeaderField: key)
        }
        return request
    }
    
    private func makeURL(route: String, params: [String: String?]) throws -> URL {
        guard var url = URL(string: baseURL) else { throw DescopeError(clientError: .invalidRoute) }
        url.appendPathComponent(basePath, isDirectory: false)
        url.appendPathComponent(route, isDirectory: false)
        guard var components = URLComponents(string: url.absoluteString) else { throw DescopeError(clientError: .invalidRoute) }
        if case let params = params.compacted(), !params.isEmpty {
            components.queryItems = params.map(URLQueryItem.init)
        }
        guard let url = components.url else { throw DescopeError(clientError: .invalidRoute) }
        return url
    }
    
    private func sendRequest(_ request: URLRequest) async throws -> (Data, URLResponse) {
        do {
            return try await session.data(for: request)
        } catch {
            throw DescopeError(networkError: error)
        }
    }
}

/// JSON Handling

private extension Dictionary {
    func compacted<T>() -> Dictionary<Key, T> where Value == T? {
        return compactMapValues { value in
            if let dict = value as? Self {
                return dict.compacted() as? T
            }
            return value
        }
    }
}

/// HTTP Headers

private let userAgent = makeUserAgent()

private func mergeHeaders(_ headers: [String: String], with defaults: [String: String], for request: URLRequest) -> [String: String] {
    var result = request.allHTTPHeaderFields ?? [:]
    result["User-Agent"] = userAgent
    if request.httpBody != nil {
        result["Content-Type"] = "application/json"
    }
    result.merge(defaults, uniquingKeysWith: { $1 })
    result.merge(headers, uniquingKeysWith: { $1 })
    return result
}

/// URLSession

private func makeURLSession() -> URLSession {
    #if DEBUG
    return URLSession(configuration: URLSessionConfiguration.default, delegate: CerificateErrorIgnorer(), delegateQueue: nil)
    #else
    return URLSession(configuration: URLSessionConfiguration.default, delegate: nil, delegateQueue: nil)
    #endif
}

#if DEBUG
private class CerificateErrorIgnorer: NSObject, URLSessionDelegate {
    func urlSession(_ session: URLSession, didReceive challenge: URLAuthenticationChallenge) async -> (URLSession.AuthChallengeDisposition, URLCredential?) {
        guard let trust = challenge.protectionSpace.serverTrust else { return (.performDefaultHandling, nil) }
        return (.useCredential, URLCredential(trust: trust))
    }
}
#endif
