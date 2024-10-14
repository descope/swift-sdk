
import AuthenticationServices

extension DescopeSDK {
    static nonisolated(unsafe) let initial: DescopeSDK = DescopeSDK(projectId: "")
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

extension DescopeLogger? {
    func callAsFunction(_ level: DescopeLogger.Level, _ message: StaticString, _ values: Any?...) {
        self?.log(level, message, values)
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
