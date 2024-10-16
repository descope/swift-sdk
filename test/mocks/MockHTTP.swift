
import Foundation
@testable import DescopeKit

class MockHTTP: URLProtocol {
    override class func canInit(with request: URLRequest) -> Bool {
        return true
    }
    
    override class func canInit(with task: URLSessionTask) -> Bool {
        return true
    }
    
    override class func canonicalRequest(for request: URLRequest) -> URLRequest {
        return request
    }
    
    override func startLoading() {
        do {
            let (response, data) = try pop()
            client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
            client?.urlProtocol(self, didLoad: data)
            client?.urlProtocolDidFinishLoading(self)
        } catch {
            client?.urlProtocol(self, didFailWithError: error)
        }
    }
    
    override func stopLoading() {
        // nothing
    }
}

extension MockHTTP {
    static let session: URLSession = {
        let sessionConfig = URLSessionConfiguration.ephemeral
        sessionConfig.protocolClasses = [MockHTTP.self]
        return URLSession(configuration: sessionConfig)
    }()
    
    static let networkClient: DescopeNetworkClient = {
        final class Client: DescopeNetworkClient {
            func call(request: URLRequest) async throws -> (Data, URLResponse) {
                return try await session.data(for: request)
            }
        }
        return Client()
    }()
}
    
extension MockHTTP {
    typealias RequestValidator = (URLRequest) -> ()

    static nonisolated(unsafe) var responses: [(statusCode: Int, data: Data?, headers: [String: String]?, error: Error?, validate: RequestValidator?)] = []

    static func push(statusCode: Int = 400, error: Error, validator: RequestValidator? = nil) {
        responses.append((statusCode, nil, nil, error, validator))
    }
    
    static func push(statusCode: Int = 200, body: String, headers: [String: String]? = nil, validator: RequestValidator? = nil) {
        responses.append((statusCode, Data(body.utf8), headers, nil, validator))
    }

    static func push(statusCode: Int = 200, json: [String: Any], headers: [String: String]? = nil, validator: RequestValidator? = nil) {
        guard let data = try? JSONSerialization.data(withJSONObject: json) else { preconditionFailure("Failed to serialize JSON") }
        responses.append((statusCode, data, headers, nil, validator))
    }
    
    func pop() throws -> (response: URLResponse, data: Data) {
        precondition(!MockHTTP.responses.isEmpty, "No mock network responses")
        
        let (statusCode, data, headers, error, validator) = MockHTTP.responses.removeFirst()
        if let validator {
            validator(request.withHTTPBody())
        }
        if let error {
            throw error
        }
        
        guard let data else { preconditionFailure("Mock response must provide either data or error") }
        guard let url = request.url else { preconditionFailure("Missing request URL") }
        guard let response = HTTPURLResponse(url: url, statusCode: statusCode, httpVersion: "HTTP/1.1", headerFields: headers) else { preconditionFailure("Failed to create response") }
        return (response, data)
    }
}

private extension URLRequest {
    func withHTTPBody() -> URLRequest {
        var request = self
        request.httpBody = httpBody ?? httpBodyStream?.readAll()
        return request
    }
}

private extension InputStream {
    func readAll() -> Data {
        open()
        defer {
            close()
        }

        let bufferSize = 1024
        let buffer = UnsafeMutablePointer<UInt8>.allocate(capacity: bufferSize)
        defer {
            buffer.deallocate()
        }
        
        var data = Data()
        while hasBytesAvailable {
            guard case let readCount = read(buffer, maxLength: bufferSize), readCount > 0 else { break }
            data.append(buffer, count: readCount)
        }
        
        return data
    }
}
