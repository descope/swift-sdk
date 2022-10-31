
import Foundation

public struct DescopeError: Error {
    var code: String
    var desc: String?
    var message: String?
    var cause: Error?
}

public extension DescopeError {
    static let networkError = DescopeError(code: "C000001")
    static let clientError = DescopeError(code: "C000002")
    
    static let badRequest = DescopeError(code: "E011001")
    static let missingArguments = DescopeError(code: "E011002")
    static let invalidRequest = DescopeError(code: "E011003")

    static let missingAccessKey = DescopeError(code: "E062802")
    static let invalidAccessKey = DescopeError(code: "E062803")
    
    static let invalidOTPCode = DescopeError(code: "E061102")
    static let tooManyOTPAttempts = DescopeError(code: "E061103")
    
    static let magicLinkExpired = DescopeError(code: "C000003")
}

public extension DescopeError {
    static func ~= (lhs: DescopeError, rhs: Error) -> Bool {
        guard let rhs = rhs as? DescopeError else { return false }
        return lhs.code == rhs.code
    }
}
