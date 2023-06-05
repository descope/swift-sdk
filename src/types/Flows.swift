
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

    /// Cancels the flow run.
    ///
    /// You can cancel any ongoing flow via the ``DescopeFlow/current`` property on
    /// ``Descope/flow`` object, or by holding on to the ``DescopeFlowRunner`` instance directly.
    ///
    ///     Task {
    ///         do {
    ///             let runner = DescopeFlowRunner(...)
    ///             let authResponse = try await Descope.flow.start(runner: runner)
    ///         } catch DescopeError.flowCancelled {
    ///             print("The flow was cancelled")
    ///         } catch {
    ///             // ...
    ///     }
    ///
    ///     // somewhere else
    ///     Descope.flow.current?.cancel()
    ///
    /// Note that cancelling the `Task` that started the flow with ``DescopeFlow/start(runner:)``
    /// has the same effect as calling this ``cancel()`` function. In other words, the following
    /// code is more or less equivalent to the one above.
    ///
    ///     let task = Task {
    ///         do {
    ///             let runner = DescopeFlowRunner(...)
    ///             let authResponse = try await Descope.flow.start(runner: runner)
    ///         } catch DescopeError.flowCancelled {
    ///             print("The flow was cancelled")
    ///         } catch {
    ///             // ...
    ///     }
    ///     task.cancel()
    ///
    /// - Important: Keep in mind that the cancellation is asynchronous and the calling code
    ///     shouldn't rely on the user interface state being updated immediately after this
    ///     function is called.
    public func cancel() {
        isCancelled = true
    }
    
    // Internal

    /// The running flow periodically checks this property for any redirect URL that was
    /// passed as a parameter to the ``handleURL(_:)`` function.
    var pendingURL: URL?
    
    /// Set to `true` after ``cancel()`` is called.
    var isCancelled: Bool = false
}
