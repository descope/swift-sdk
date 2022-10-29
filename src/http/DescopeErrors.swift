
import Foundation

public class DescopeError: Error {
    static var errorDomain = "com.descope.ServerError"
    var code: String
    var desc: String?
    var message: String?
    
    init(code: String, desc: String? = nil, message: String? = nil) {
        self.code = code
        self.message = message
        self.desc = desc
    }
    
    convenience init?(responseData: Data) {
        guard let dict = try? JSONSerialization.jsonObject(with: responseData) as? [String: Any] else { return nil }
        guard let code = dict["errorCode"] as? String else { return nil }
        var desc: String? = nil
        if let descString = dict["errorDescription"] as? String, !descString.isEmpty {
            desc = descString
        }
        var message: String? = nil
        if let messageString = dict["message"] as? String, !messageString.isEmpty {
            message = messageString
        }
        self.init(code: code, desc: desc, message: message)
    }
}

public extension DescopeError {
    // Common
    static let badRequest = DescopeError(code: "E011001")
    static let missingArguments = DescopeError(code: "E011002")
    static let invalidRequest = DescopeError(code: "E011003")

    // Onetime
    static let missingAccessKey = DescopeError(code: "E062802")
    static let invalidAccessKey = DescopeError(code: "E062803")
    static let otpInvalidCode = DescopeError(code: "E061102")
    static let otpTooManyAttempts = DescopeError(code: "E061103")
}

extension DescopeError: CustomStringConvertible {
    public var description: String {
        var str = "DescopeError(Code=\(code)"
        if let desc {
            str += " Description=\"\(desc)\""
        }
        if let message {
            str += " Message=\"\(message)\""
        }
        str += ")"
        return str
    }
}

extension DescopeError: LocalizedError {
    public var errorDescription: String? {
        return description
    }
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
