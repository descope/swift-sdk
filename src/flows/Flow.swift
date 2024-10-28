
#if os(iOS)

import Foundation

public enum DescopeFlowState: String {
    case initial

    case started

    case ready

    case failed

    case finished
}

/// A helper object that encapsulates a single flow run.
@MainActor
public class DescopeFlow {
    /// TODO
    public static var current: DescopeFlow?

    /// The URL where the flow is hosted.
    public let url: String

    /// TODO
    public var oauthNativeProvider: OAuthProvider?

    public var requestTimeoutInterval: TimeInterval?

    /// Creates a new ``DescopeFlow`` object that encapsulates a single flow run.
    ///
    /// - Parameter url: The URL where the flow is hosted.
    public init(url: String) {
        self.url = url
    }

    /// Creates a new ``DescopeFlow`` object that encapsulates a single flow run.
    ///
    /// - Parameter url: The URL where the flow is hosted.
    public init(url: URL) {
        self.url = url.absoluteString
    }

    /// Resumes a running flow that's waiting for Magic Link authentication.
    ///
    /// When a flow performs authentication with Magic Link at some point it will wait
    /// for the user to receive an email and tap on the authentication URL provided inside.
    /// The host application is expected to intercept this URL via Universal Links and
    /// resume the running flow with it.
    ///
    /// You can do this by first getting a reference to the current running flow from
    /// the ``DescopeFlow/current`` property and then calling the ``resume(with:)`` method
    /// with the URL from the Universal Link.
    ///
    ///     @main
    ///     struct MyApp: App {
    ///         // ...
    ///
    ///         var body: some Scene {
    ///             WindowGroup {
    ///                 ContentView().onOpenURL { url in
    ///                     DescopeFlow.current?.resume(with: url)
    ///                 }
    ///             }
    ///         }
    ///     }
    public func resume(with url: URL) {
        resume?(url)
    }

    // Internal

    typealias ResumeClosure = @MainActor (URL) -> ()

    /// The running flow periodically checks this property to for any redirect URL from calls
    /// to the ``handleURL(_:)`` function.
    var resume: ResumeClosure?
}

/// TODO
extension DescopeFlow: CustomStringConvertible {
    /// Returns a textual representation of this ``DescopeFlow`` object.
    ///
    /// It returns a string with the URL of the flow.
    public nonisolated var description: String {
        return "DescopeFlow(url: \"\(url)\")"
    }
}

#endif
