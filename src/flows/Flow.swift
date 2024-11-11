
#if os(iOS)

import Foundation

/// The state of the flow or presenting object.
public enum DescopeFlowState: String {
    /// The flow hasn't been started yet.
    case initial

    /// The flow is being loaded but is not ready yet.
    case started

    /// The flow finished loading and can be shown.
    case ready

    /// The flow failed to load or there was some other error.
    case failed

    /// The flow completed the authentication successfully.
    case finished
}

/// A helper object that encapsulates a single flow run for authenticating a user.
///
/// You can use Descope Flows as a visual no-code interface to build screens and authentication
/// flows for common user interactions with your application.
///
/// Flows are hosted on a webpage and are run by creating an instance of
/// ``DescopeFlowViewController``, ``DescopeFlowView``, or ``DescopeFlowCoordinator`` and
/// calling `start(flow:)`.
///
/// There are some preliminary setup steps you might need to do:
///
/// - As a prerequisite, the flow itself must be created and hosted somewhere on the web. You can
///     either host it on your own web server or use Descope's auth hosting. Read more [here](https://docs.descope.com/auth-hosting-app).
///
/// - You should configure any required Descope authentication methods in the [Descope console](https://app.descope.com/settings/authentication)
///     before making use of them in a Descope Flow. Some of the default configurations might work
///     well enough to start with, but it is likely that some changes will be needed before release.
///
/// - For flows that use `Magic Link` authentication you will need to set up [Universal Links](https://developer.apple.com/documentation/xcode/supporting-universal-links-in-your-app)
///     in your app. See the documentation for ``resume(with:)`` for more details.
///
/// - You can leverage the native `Sign in with Apple` automatically for flows that use `OAuth`
///     by setting the ``oauthProvider`` property and configuring native OAuth in your app. See the
///     documentation for ``DescopeOAuth/native(provider:options:)`` for more details.
///
/// - SeeAlso: You can read more about Descope Flows on the [docs website](https://docs.descope.com/flows).
@MainActor
public class DescopeFlow {
    /// Returns the ``DescopeFlow`` object for the current running flow or
    /// `nil` if no flow is currently running.
    public internal(set) static weak var current: DescopeFlow?

    /// The URL where the flow is hosted.
    public let url: URL

    /// An optional instance of ``DescopeSDK`` to use for running the flow.
    ///
    /// If you're not using the shared ``Descope`` singleton and passing around an instance of
    /// the ``DescopeSDK`` class instead you must set this property before starting the flow.
    public var descope: DescopeSDK?

    /// The id of the oauth provider that should leverage the native "Sign in with Apple"
    /// dialog instead of opening a web browser.
    ///
    /// This will usually either be `.apple` or the name of a custom OAuth provider you've
    /// created in the [Descope Console](https://app.descope.com/settings/authentication/social)
    /// that's been configured for Apple.
    public var oauthProvider: OAuthProvider?

    /// An optional universal link URL to use when sending magic link emails.
    ///
    /// You only need to set this if you explicitly want to override whichever URL is
    /// configured in the flow or in the Descope project, perhaps because the app cannot
    /// be configured for universal links using the same redirect URL as on the web.
    public var magicLinkRedirect: URL?

    /// An optional timeout interval to set on the `URLRequest` object used for loading
    /// the flow webpage. If this is not set the platform default value is be used.
    public var requestTimeoutInterval: TimeInterval?

    /// Creates a new ``DescopeFlow`` object that encapsulates a single flow run.
    ///
    /// - Parameter url: The URL where the flow is hosted.
    public init(url: URL) {
        self.url = url
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

    /// While the flow is running this is set to a closure with a weak reference to
    /// the ``DescopeFlowCoordinator`` to provide it with the resume URL.
    var resume: ResumeClosure?
}

extension DescopeFlow: CustomStringConvertible {
    /// Returns a textual representation of this ``DescopeFlow`` object.
    ///
    /// It returns a string with the initial URL of the flow.
    public nonisolated var description: String {
        return "DescopeFlow(url: \"\(url)\")"
    }
}

#endif
