
import Foundation

enum NetworkError: Error {
    case offline
    case timeout
    case aborted
    case other(Error)
}

enum HttpError: Error {
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

/// Conversions

extension NetworkError {
    init(_ error: Error) {
        let err = error as NSError
        switch err.code {
        case NSURLErrorTimedOut: self = .timeout
        case NSURLErrorNotConnectedToInternet: self = .offline
        case NSURLErrorNetworkConnectionLost: self = .aborted
        default: self = .other(error)
        }
    }
}

extension HttpError {
    init?(_ statusCode: Int) {
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

/// Descriptions

extension NetworkError: CustomStringConvertible {
    var description: String {
        switch self {
        case .offline: return "The internet connection appears to be offline"
        case .timeout: return "The request timed out"
        case .aborted: return "The request was aborted"
        case .other(let err): return err.localizedDescription
        }
    }
}

extension HttpError: CustomStringConvertible {
    var description: String {
        switch self {
        case .invalidRoute: return "The request url was invalid"
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
