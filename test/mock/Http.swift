
import Foundation
@testable import DescopeKit

struct MockResponse: Decodable, Equatable {
    var id: Int
    var st: String
    
    static let instance = MockResponse(id: 7, st: "foo")
    static let json: [String: Any] = ["id": instance.id, "st": instance.st]
}

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
    typealias RequestValidator = (URLRequest) -> ()
    
    static var session: URLSession = {
        let sessionConfig = URLSessionConfiguration.ephemeral
        sessionConfig.protocolClasses = [MockHTTP.self]
        return URLSession(configuration: sessionConfig)
    }()
    
    private static var responses: [(statusCode: Int, data: Data?, error: Error?, validate: RequestValidator?)] = []
    
    static func push(statusCode: Int = 400, error: Error, validator: RequestValidator? = nil) {
        responses.append((statusCode, nil, error, validator))
    }
    
    static func push(statusCode: Int = 200, json: [String: Any], validator: RequestValidator? = nil) {
        guard let data = try? JSONSerialization.data(withJSONObject: json) else { preconditionFailure("Failed to serialize JSON") }
        responses.append((statusCode, data, nil, validator))
    }
    
    func pop() throws -> (response: URLResponse, data: Data) {
        precondition(!MockHTTP.responses.isEmpty, "No mock network responses")
        
        let (statusCode, data, error, validator) = MockHTTP.responses.removeFirst()
        if let validator {
            validator(request.withHTTPBody())
        }
        if let error {
            throw error
        }
        
        guard let data else { preconditionFailure("Mock response must provide either data or error") }
        guard let url = request.url else { preconditionFailure("Missing request URL") }
        guard let response = HTTPURLResponse(url: url, statusCode: statusCode, httpVersion: "HTTP/1.1", headerFields: nil) else { preconditionFailure("Failed to create response") }
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
