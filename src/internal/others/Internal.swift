
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
