
import Foundation
import AuthenticationServices

@MainActor
public class DescopeFlowRunner {
    public let flowURL: String
    
    public var presentationContextProvider: ASWebAuthenticationPresentationContextProviding?
    
    public init(flowURL: String, presentationContextProvider: ASWebAuthenticationPresentationContextProviding) {
        self.flowURL = flowURL
        self.presentationContextProvider = presentationContextProvider
    }
    
    public func handleURL(_ url: URL) {
        pendingURL = url
    }

    public func cancel() {
        
    }

    var pendingURL: URL?
    
    var isCancelled: Bool = false
}
