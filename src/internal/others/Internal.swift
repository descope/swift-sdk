
import AuthenticationServices

extension DescopeConfig {
    static let initial: DescopeConfig = DescopeConfig(projectId: "")
}

extension DescopeError {
    func with(desc: String) -> DescopeError {
        return DescopeError(code: code, desc: desc, message: message, cause: cause)
    }
    
    func with(message: String) -> DescopeError {
        return DescopeError(code: code, desc: desc, message: message, cause: cause)
    }
    
    func with(cause: Error) -> DescopeError {
        return DescopeError(code: code, desc: desc, message: message, cause: cause)
    }
}

extension Data {
    init?(base64URLEncoded base64URLString: String, options: Base64DecodingOptions = []) {
        var str = base64URLString
            .replacingOccurrences(of: "-", with: "+")
            .replacingOccurrences(of: "_", with: "/")
        if str.count % 4 > 0 {
            str.append(String(repeating: "=", count: 4 - str.count % 4))
        }
        self.init(base64Encoded: str, options: options)
    }
    
    func base64URLEncodedString(options: Base64EncodingOptions = []) -> String {
        return base64EncodedString(options: options)
            .replacingOccurrences(of: "+", with: "-")
            .replacingOccurrences(of: "/", with: "_")
            .replacingOccurrences(of: "=", with: "")
    }
}

class DefaultPresentationContextProvider: NSObject, ASWebAuthenticationPresentationContextProviding, ASAuthorizationControllerPresentationContextProviding {
    func presentationAnchor(for session: ASWebAuthenticationSession) -> ASPresentationAnchor {
        return presentationAnchor
    }
    
    func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
        return presentationAnchor
    }
    
    private var presentationAnchor: ASPresentationAnchor {
#if os(macOS)
        return ASPresentationAnchor()
#else
        let scene = UIApplication.shared.connectedScenes
            .filter { $0.activationState == .foregroundActive }
            .compactMap { $0 as? UIWindowScene }
            .first
        
        let keyWindow = scene?.windows
            .first { $0.isKeyWindow }
        
        return keyWindow ?? ASPresentationAnchor()
#endif
    }
}

typealias AuthorizationDelegateCompletion = (Result<ASAuthorization, Error>) -> Void

class AuthorizationDelegate: NSObject, ASAuthorizationControllerDelegate {
    var completion: AuthorizationDelegateCompletion?
    
    func authorizationController(controller: ASAuthorizationController, didCompleteWithAuthorization authorization: ASAuthorization) {
        completion?(.success(authorization))
        completion = nil
    }
    
    func authorizationController(controller: ASAuthorizationController, didCompleteWithError error: Error) {
        completion?(.failure(error))
        completion = nil
    }
}

// JSON

struct JSONCodingKeys: CodingKey {
    var stringValue: String
    var intValue: Int?
    
    init(stringValue: String) {
        self.stringValue = stringValue
    }
    
    init(intValue: Int) {
        self.init(stringValue: "\(intValue)")
        self.intValue = intValue
    }
}

func decodeJson(container: KeyedDecodingContainer<JSONCodingKeys>) -> [String: Any] {
    var decoded: [String: Any] = [:]
    for key in container.allKeys {
        if let boolValue = try? container.decode(Bool.self, forKey: key) {
            decoded[key.stringValue] = boolValue
        } else if let intValue = try? container.decode(Int.self, forKey: key) {
            decoded[key.stringValue] = intValue
        } else if let doubleValue = try? container.decode(Double.self, forKey: key) {
            decoded[key.stringValue] = doubleValue
        } else if let stringValue = try? container.decode(String.self, forKey: key) {
            decoded[key.stringValue] = stringValue
        } else if let nestedContainer = try? container.nestedContainer(keyedBy: JSONCodingKeys.self, forKey: key) {
            decoded[key.stringValue] = decodeJson(container: nestedContainer)
        } else if var nestedUnkeyedContainer = try? container.nestedUnkeyedContainer(forKey: key) {
            decoded[key.stringValue] = decodeJson(unkeydContainer: &nestedUnkeyedContainer)
        }
    }
    return decoded
}


func decodeJson(unkeydContainer: inout UnkeyedDecodingContainer) -> [Any] {
    var decoded: [Any] = []
    while unkeydContainer.isAtEnd == false {
        if let value = try? unkeydContainer.decode(Bool.self) {
            decoded.append(value)
        } else if let value = try? unkeydContainer.decode(Int.self) {
            decoded.append(value)
        } else if let value = try? unkeydContainer.decode(Double.self) {
            decoded.append(value)
        } else if let value = try? unkeydContainer.decode(String.self) {
            decoded.append(value)
        } else if let _ = try? unkeydContainer.decode(String?.self) {
            continue // Skip over `null` values
        } else if let nestedContainer = try? unkeydContainer.nestedContainer(keyedBy: JSONCodingKeys.self) {
            decoded.append(decodeJson(container: nestedContainer))
        } else if var nestedUnkeyedContainer = try? unkeydContainer.nestedUnkeyedContainer() {
            decoded.append(decodeJson(unkeydContainer: &nestedUnkeyedContainer))
        }
    }
    return decoded
}

extension Dictionary<String, Any> {
    func encodeJson(container: inout KeyedEncodingContainer<JSONCodingKeys>) throws {
        try forEach({ (key, value) in
            let encodingKey = JSONCodingKeys(stringValue: key)
            switch value {
            case let value as Bool:
                try container.encode(value, forKey: encodingKey)
            case let value as Int:
                try container.encode(value, forKey: encodingKey)
            case let value as Double:
                try container.encode(value, forKey: encodingKey)
            case let value as String:
                try container.encode(value, forKey: encodingKey)
            case let value as String?:
                try container.encode(value, forKey: encodingKey)
            case let value as [String: Any]:
                var nestedContainer = container.nestedContainer(keyedBy: JSONCodingKeys.self, forKey: encodingKey)
                try value.encodeJson(container: &nestedContainer)
            case let value as [Any]:
                var nestedUnkeyedContainer = container.nestedUnkeyedContainer(forKey: encodingKey)
                try value.encodeJson(container: &nestedUnkeyedContainer)
            default:
                throw DescopeError.encodeError.with(message: "Invalid JSON value in dict: \(key): \(value)")
            }
        })
    }
}

extension Array<Any> {
    func encodeJson(container: inout UnkeyedEncodingContainer) throws {
        for value in self {
            switch value {
            case let value as Bool:
                try container.encode(value)
            case let value as Int:
                try container.encode(value)
            case let value as Double:
                try container.encode(value)
            case let value as String:
                try container.encode(value)
            case let value as [String: Any]:
                var nestedContainer = container.nestedContainer(keyedBy: JSONCodingKeys.self)
                try value.encodeJson(container: &nestedContainer)
            case let value as [Any]:
                var nestedUnkeyedContainer = container.nestedUnkeyedContainer()
                try value.encodeJson(container: &nestedUnkeyedContainer)
            default:
                throw DescopeError.encodeError.with(message: "Invalid JSON value in array: \(value)")
            }
        }
    }
}
