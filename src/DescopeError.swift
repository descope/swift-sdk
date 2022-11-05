
import Foundation

public struct DescopeError: Error {
    var code: String
    var desc: String?
    var message: String?
    var cause: Error?
}

public extension DescopeError {
    static let networkError = DescopeError(code: "C010001")
    static let serverError = DescopeError(code: "C010002")
    
    static let badRequest = DescopeError(code: "E011001")
    static let missingArguments = DescopeError(code: "E011002")
    static let invalidRequest = DescopeError(code: "E011003")

    static let missingAccessKey = DescopeError(code: "E062802")
    static let invalidAccessKey = DescopeError(code: "E062803")
    
    static let invalidOTPCode = DescopeError(code: "E061102")
    static let tooManyOTPAttempts = DescopeError(code: "E061103")
    
    static let magicLinkExpired = DescopeError(code: "C010003")
}

extension DescopeError: Equatable {
    public static func == (lhs: DescopeError, rhs: DescopeError) -> Bool {
        return lhs.code == rhs.code
    }

    public static func ~= (lhs: DescopeError, rhs: Error) -> Bool {
        guard let rhs = rhs as? DescopeError else { return false }
        return lhs == rhs
    }
}

extension DescopeError: CustomStringConvertible {
    public var description: String {
        var str = "DescopeError(code: \"\(code)\""
        if let desc {
            str += ", description: \"\(desc)\""
        }
        if let message {
            str += ", message: \"\(message)\""
        }
        if let cause {
            str += ", cause: {\(cause)}"
        }
        str += ")"
        return str
    }
}

extension DescopeError: LocalizedError {
    public var errorDescription: String? {
        var str: String
        if let desc {
            str = "\(desc) [\(code)]"
        } else if let cause = cause as? NSError {
            str = "\(cause.localizedDescription) (\(cause.code))"
        } else {
            str = "Descope error [\(code)]"
        }
        if let message {
            str += ": \"\(message)\""
        }
        return str
    }
}
