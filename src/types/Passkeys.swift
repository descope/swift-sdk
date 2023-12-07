
import AuthenticationServices

/// A helper object that encapsulates a single authentication with passkeys.
@MainActor
public class DescopePasskeyRunner {
    /// The domain of the web credential as configured in the Xcode project's
    /// associated domains.
    public var domain: String
    
    /// Determines where in an application's UI the authentication view should be shown.
    ///
    /// Setting this delegate object is optional as the ``DescopePasskeyRunner`` will look for
    /// a suitable anchor to show the authentication view. In case you need to override the
    /// default behavior set your own delegate on this property.
    ///
    /// - Note: This property is marked as `weak` like all delegate properties, so if you
    ///     set a custom object make sure it's retained elsewhere.
    public weak var presentationContextProvider: ASAuthorizationControllerPresentationContextProviding?
    
    /// Creates a new ``DescopePasskeyRunner`` object that encapsulates a single
    /// passkey authentication run.
    ///
    /// - Parameter domain: The domain of the web credential as configured in the Xcode
    ///     project's associated domains.
    public init(domain: String) {
        self.domain = domain
    }
    
    /// Cancels the passkeys run.
    ///
    /// You can cancel any ongoing passkey authentication via the ``DescopePasskey/current``
    /// property on the ``Descope/passkey`` object, or by holding on to the ``DescopePasskeyRunner``
    /// instance directly. This method can be safely called multiple times.
    ///
    ///     do {
    ///         let runner = DescopePasskeyRunner(domain: "acmecorp.com")
    ///         let authResponse = try await Descope.passkey.signIn(
    ///                 loginId: "user@acmecorp.com", options: [], runner: runner)
    ///         let session = DescopeSession(from: authResponse)
    ///         Descope.sessionManager.manageSession(session)
    ///     } catch DescopeError.passkeyCancelled {
    ///         print("The authentication was cancelled")
    ///     } catch {
    ///         // ...
    ///     }
    ///
    ///     // somewhere else
    ///     Descope.passkey.current?.cancel()
    ///
    /// Note that cancelling the `Task` that started the passkey authentication has the
    /// same effect as calling this ``cancel()`` function.
    ///
    /// In any case, when a runner is cancelled the ``DescopePasskey`` calls always
    /// throw a ``DescopeError/passkeyCancelled`` error.
    ///
    /// - Important: Calling ``cancel()`` will only dismiss the authentication view when running
    ///     on iOS 16 / macOS 13 or newer, as this functionality was not supported in earlier
    ///     releases. Note that even when running on older versions, once this method is called
    ///     the async authentication call will eventually throw a ``DescopeError/passkeyCancelled``
    ///     error no matter what the user does with the authentication view.
    public func cancel() {
        guard !isCancelled else { return }
        isCancelled = true
        cancellation?()
    }

    /// Returns whether this runner was cancelled.
    public private(set) var isCancelled: Bool = false

    // Internal

    /// Returns the ``presentationContextProvider`` or the default provider if none was set.
    var contextProvider: ASAuthorizationControllerPresentationContextProviding {
        return presentationContextProvider ?? defaultContextProvider
    }
    
    /// The default context provider that looks for the first key window in the active scene.
    private let defaultContextProvider = DefaultPresentationContextProvider()
    
    /// Cancels the authentication encapsulated by this runner.
    var cancellation: (() -> Void)?
}
