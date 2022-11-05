
import Foundation

public struct DescopeError: Error {
    var code: String
    var desc: String?
    var message: String?
    var cause: Error?
}

extension DescopeError {
    public static let networkError = DescopeError(code: "C010001")
    
    public static let badRequest = DescopeError(code: "E011001")
    public static let missingArguments = DescopeError(code: "E011002")
    public static let invalidRequest = DescopeError(code: "E011003")

    public static let missingAccessKey = DescopeError(code: "E062802")
    public static let invalidAccessKey = DescopeError(code: "E062803")
    
    public static let invalidOTPCode = DescopeError(code: "E061102")
    public static let tooManyOTPAttempts = DescopeError(code: "E061103")
    
    public static let magicLinkExpired = DescopeError(code: "C020001")
    
    // internal
    static let serverError = DescopeError(code: "C010002")
    static let decodeError = DescopeError(code: "C010003")
    static let encodeError = DescopeError(code: "C010004")
    static let tokenError = DescopeError(code: "C010005")
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
            str = "\(cause.localizedDescription) (\(code):\(cause.code))"
        } else {
            str = "Descope error [\(code)]"
        }
        if let message {
            str += ": \"\(message)\""
        }
        return str
    }
}

extension DescopeError {
    func with(desc: String) -> DescopeError {
        return DescopeError(code: code, desc: desc, message: message, cause: cause)
    }
    
    func with(cause: Error) -> DescopeError {
        return DescopeError(code: code, desc: desc, message: message, cause: cause)
    }
}
