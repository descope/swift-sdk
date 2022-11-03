
import Foundation

// Server errors

extension DescopeError {
    static func from(responseData data: Data) -> DescopeError? {
        guard let dict = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else { return nil }
        guard let code = dict["errorCode"] as? String else { return nil }
        var desc: String? = nil
        if let value = dict["errorDescription"] as? String, !value.isEmpty {
            desc = value
        }
        var message: String? = nil
        if let value = dict["message"] as? String, !value.isEmpty {
            message = value
        }
        return DescopeError(code: code, desc: desc, message: message)
    }
}

// Network errors

extension DescopeError {
    init(networkError: Error) {
        self.init(code: DescopeError.networkError.code, desc: nil, message: nil, cause: networkError)
    }
}

// Client errors

extension DescopeError {
    static func from(statusCode: Int) -> DescopeError? {
        guard let clientError = ClientError(statusCode: statusCode) else { return nil }
        return DescopeError(clientError: clientError)
    }
    
    init(clientError: ClientError) {
        self.init(code: DescopeError.clientError.code, desc: clientError.description, message: nil, cause: nil)
    }
}

enum ClientError: Error {
    case invalidRoute
    case invalidResponse
    case unexpectedResponse(Int)
    case badRequest
    case notFound
    case unauthorized
    case forbidden
    case serverFailure(Int)
    case serverUnreachable
}

extension ClientError {
    init?(statusCode: Int) {
        switch statusCode {
        case 200...299: return nil
        case 400: self = .badRequest
        case 401: self = .unauthorized
        case 403: self = .forbidden
        case 404: self = .notFound
        case 500, 503: self = .serverFailure(statusCode)
        case 502, 504: self = .serverUnreachable
        default: self = .unexpectedResponse(statusCode)
        }
    }
}

extension ClientError: CustomStringConvertible {
    var description: String {
        switch self {
        case .invalidRoute: return "The request URL was invalid"
        case .invalidResponse: return "The server returned an unexpected response"
        case .unexpectedResponse(let code): return "The server returned status code \(code)"
        case .badRequest: return "The request was invalid"
        case .notFound: return "The resource was not found"
        case .unauthorized: return "The request was unauthorized"
        case .forbidden: return "The request was forbidden"
        case .serverFailure(let code): return "The server failed with status code \(code)"
        case .serverUnreachable: return "The server was unreachable"
        }
    }
}
