
#if os(iOS)

import UIKit
import WebKit

/// A set of delegate methods for events about the flow running in a ``DescopeFlowCoordinator``.
@MainActor
public protocol DescopeFlowCoordinatorDelegate: AnyObject {
    func coordinatorDidUpdateState(_ coordinator: DescopeFlowCoordinator, to state: DescopeFlowState, from previous: DescopeFlowState)
    func coordinatorDidBecomeReady(_ coordinator: DescopeFlowCoordinator)
    func coordinatorDidInterceptNavigation(_ coordinator: DescopeFlowCoordinator, url: URL, external: Bool)
    func coordinatorDidFail(_ coordinator: DescopeFlowCoordinator, error: DescopeError)
    func coordinatorDidFinish(_ coordinator: DescopeFlowCoordinator, response: AuthenticationResponse)
}

/// A helper class for running Descope Flows.
///
/// You can use a ``DescopeFlowCoordinator`` to run a flow in a `WKWebView` that was created
/// manually and attached to the coordinator, but in almost all scenarios it should be more
/// convenient to use a ``DescopeFlowViewController`` or a ``DescopeFlowView`` instead.
///
/// To start a flow in a ``DescopeFlowCoordinator``, first create a `WKWebViewConfiguration`
/// object and bootstrap it by calling ``prepare(configuration:)``, then create an instance
/// of `WKWebView` and pass the bootstrapped configuration to the initializer. Attach the
/// webview to the coordinator by setting the ``webView`` property, and finally call
/// the ``start(flow:)`` function.
@MainActor
public class DescopeFlowCoordinator {

    /// A delegate object for receiving events about the state of the flow.
    public weak var delegate: DescopeFlowCoordinatorDelegate?

    /// The current state of the flow in the ``DescopeFlowCoordinator``.
    public private(set) var state: DescopeFlowState = .initial {
        didSet {
            delegate?.coordinatorDidUpdateState(self, to: state, from: oldValue)
        }
    }

    /// A list of hooks that customize the behavior of the flow.
    public var hooks: [DescopeFlowHook] = []

    /// The instance of `WKWebView` that was attached to the coordinator.
    ///
    /// When using a ``DescopeFlowView`` or ``DescopeFlowViewController`` this property
    /// is set automatically to the webview created by them.
    public var webView: WKWebView? {
        didSet {
            bridge.webView = webView
            updateLayoutObserver()
        }
    }

    // Initialization

    private let bridge: FlowBridge

    private var logger: DescopeLogger?

    public init() {
        bridge = FlowBridge()
        bridge.delegate = self
    }

    public func prepare(configuration: WKWebViewConfiguration) {
        bridge.prepare(configuration: configuration)
    }

    // Flow

    public private(set) var flow: DescopeFlow? {
        willSet {
            flow?.resume = nil
        }
        didSet {
            flow?.resume = resumeClosure
            logger = flow?.config.logger
            bridge.logger = logger
        }
    }

    public func start(flow: DescopeFlow) {
        #if DEBUG
        precondition(webView != nil, "The flow coordinator's webView property must be set before starting the flow")
        precondition(flow.config.projectId != "", "The Descope singleton must be setup or an instance of DescopeSDK must be set on the flow")
        #endif

        logger(.info, "Starting flow authentication", flow)
        self.flow = flow
        DescopeFlow.current = flow

        state = .started
        loadURL(flow.url)
    }

    private func loadURL(_ url: URL) {
        var request = URLRequest(url: url)
        if let timeout = flow?.requestTimeoutInterval {
            request.timeoutInterval = timeout
        }
        webView?.load(request)
    }

    // WebView

    public func evaluateJavaScript(_ code: String) async -> Any? {
        return await bridge.evaluateJavaScript(code)
    }

    public func runJavaScript(_ code: String) {
        bridge.runJavaScript(code)
    }

    public func addStyles(_ css: String) {
        bridge.addStyles(css)
    }

    // Hooks

    private let defaultHooks: [DescopeFlowHook] = [.disableZoom, .disableTouchCallouts, .disableTextSelection]

    private func executeHooks(event: DescopeFlowHook.Event) {
        for hook in defaultHooks + hooks where event == hook.event {
            hook.execute(coordinator: self)
        }
    }

    // Layout

    private var layoutObserver: WebViewLayoutObserver?

    private func updateLayoutObserver() {
        if let webView {
            layoutObserver = WebViewLayoutObserver(webView: webView, handler: { [weak self] in self?.handleLayoutChange() })
        } else {
            layoutObserver = nil
        }
    }

    private func handleLayoutChange() {
        executeHooks(event: .layout)
    }

    // State

    private func ensureState(_ states: DescopeFlowState...) -> Bool {
        guard states.contains(state) else {
            logger(.error, "Unexpected flow state", state, states)
            return false
        }
        return true
    }

    private func sendResponse(_ response: FlowBridgeResponse) {
        guard ensureState(.ready) else { return }
        bridge.send(response: response)
    }

    // Resume

    private func resume(_ url: URL) {
        logger(.info, "Received URL for resuming flow", url)
        sendResponse(.magicLink(url: url.absoluteString))
    }

    private lazy var resumeClosure: DescopeFlow.ResumeClosure = { [weak self] url in
        self?.resume(url)
    }

    // Events

    private func handleFailure(_ error: DescopeError) {
        guard ensureState(.started, .ready, .failed) else { return }

        // we allow multiple failure events and swallow them here instead of showing a warning above,
        // so that the bridge can just delegate any failures to the coordinator without having to
        // keep its own state to ensure it only reports a single failure
        guard state != .failed  else { return }

        if DescopeFlow.current === flow {
            DescopeFlow.current = nil
        }
        
        state = .failed
        delegate?.coordinatorDidFail(self, error: error)
    }

    private func handleStarted() {
        executeHooks(event: .started)
    }

    private func handleLoaded() {
        guard ensureState(.started) else { return }
        executeHooks(event: .loaded)
    }

    private func handleReady() {
        guard ensureState(.started) else { return }
        bridge.set(oauthProvider: flow?.oauthProvider?.name, magicLinkRedirect: flow?.magicLinkRedirect?.absoluteString)
        state = .ready
        executeHooks(event: .ready)
        delegate?.coordinatorDidBecomeReady(self)
    }

    private func handleRequest(_ request: FlowBridgeRequest) {
        guard ensureState(.ready) else { return }
        switch request {
        case let .oauthNative(clientId, stateId, nonce, implicit):
            handleOAuthNative(clientId: clientId, stateId: stateId, nonce: nonce, implicit: implicit)
        case let .webAuth(variant, startURL, finishURL):
            handleWebAuth(variant: variant, startURL: startURL, finishURL: finishURL)
        }
    }

    // Authentication

    private func handleAuthentication(_ data: Data) {
        logger(.info, "Finishing flow authentication")
        Task {
            guard let authResponse = await parseAuthentication(data) else { return }
            guard ensureState(.ready) else { return }
            if DescopeFlow.current === flow {
                DescopeFlow.current = nil
            }
            state = .finished
            delegate?.coordinatorDidFinish(self, response: authResponse)
        }
    }

    private func parseAuthentication(_ data: Data) async -> AuthenticationResponse? {
        do {
            guard let webView else { return nil }
            let cookies = await webView.configuration.websiteDataStore.httpCookieStore.cookies(for: webView.url)
            var jwtResponse = try JSONDecoder().decode(DescopeClient.JWTResponse.self, from: data)
            try jwtResponse.setValues(from: data, cookies: cookies)
            return try jwtResponse.convert()
        } catch {
            logger(.error, "Unexpected error handling authentication response", error)
            handleFailure(DescopeError.flowFailed.with(message: "No valid authentication tokens found"))
            return nil
        }
    }

    // OAuth Native

    private func handleOAuthNative(clientId: String, stateId: String, nonce: String, implicit: Bool) {
        logger(.info, "Requesting authentication using Sign in with Apple", clientId)
        Task {
            await performOAuthNative(stateId: stateId, nonce: nonce, implicit: implicit)
        }
    }

    private func performOAuthNative(stateId: String, nonce: String, implicit: Bool) async {
        do {
            let (authorizationCode, identityToken, user) = try await OAuth.performNativeAuthentication(nonce: nonce, implicit: implicit, logger: logger)
            sendResponse(.oauthNative(stateId: stateId, authorizationCode: authorizationCode, identityToken: identityToken, user: user))
        } catch .oauthNativeCancelled {
            sendResponse(.failure("OAuthNativeCancelled"))
        } catch {
            sendResponse(.failure("OAuthNativeFailed"))
        }
    }

    // OAuth / SSO

    private func handleWebAuth(variant: String, startURL: URL, finishURL: URL?) {
        logger(.info, "Requesting web authentication", startURL)
        Task {
            await performWebAuth(variant: variant, startURL: startURL, finishURL: finishURL)
        }
    }

    private func performWebAuth(variant: String, startURL: URL, finishURL: URL?) async {
        do {
            let exchangeCode = try await WebAuth.performAuthentication(url: startURL, accessSharedUserData: true, logger: logger)
            sendResponse(.webAuth(variant: variant, exchangeCode: exchangeCode))
        } catch .webAuthCancelled {
            sendResponse(.failure("WebAuthCancelled"))
        } catch {
            sendResponse(.failure("WebAuthFailed"))
        }
    }
}

extension DescopeFlowCoordinator: FlowBridgeDelegate {
    func bridgeDidStartLoading(_ bridge: FlowBridge) {
        handleStarted()
    }

    func bridgeDidFailLoading(_ bridge: FlowBridge, error: DescopeError) {
        handleFailure(error)
    }

    func bridgeDidFinishLoading(_ bridge: FlowBridge) {
        handleLoaded()
    }

    func bridgeDidBecomeReady(_ bridge: FlowBridge) {
        handleReady()
    }

    func bridgeDidInterceptNavigation(_ bridge: FlowBridge, url: URL, external: Bool) {
        delegate?.coordinatorDidInterceptNavigation(self, url: url, external: external)
    }

    func bridgeDidReceiveRequest(_ bridge: FlowBridge, request: FlowBridgeRequest) {
        handleRequest(request)
    }

    func bridgeDidFailAuthentication(_ bridge: FlowBridge, error: DescopeError) {
        handleFailure(error)
    }

    func bridgeDidFinishAuthentication(_ bridge: FlowBridge, data: Data) {
        handleAuthentication(data)
    }
}

private extension DescopeFlow {
    var config: DescopeConfig {
        return descope?.config ?? Descope.sdk.config
    }
}

private extension WKHTTPCookieStore {
    func cookies(for url: URL?) async -> [HTTPCookie] {
        return await allCookies().filter { cookie in
            guard let domain = url?.host else { return true }
            if cookie.domain.hasPrefix(".") {
                return domain.hasSuffix(cookie.domain) || domain == cookie.domain.dropFirst()
            }
            return domain == cookie.domain
        }
    }
}

@MainActor
private class WebViewLayoutObserver: NSObject {
    @objc let webView: WKWebView
    var observation: NSKeyValueObservation?

    init(webView: WKWebView, handler: @escaping @MainActor () -> Void) {
        self.webView = webView
        super.init()

        observation = observe(\.webView.frame, changeHandler: { observer, change in
            Task { @MainActor in
                handler()
            }
        })
    }
}

#endif
