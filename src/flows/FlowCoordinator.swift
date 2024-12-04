
#if os(iOS)

import UIKit
import WebKit

/// A set of delegate methods for events about the flow running in a ``DescopeFlowCoordinator``.
@MainActor
public protocol DescopeFlowCoordinatorDelegate: AnyObject {
    func coordinatorDidUpdateState(_ coordinator: DescopeFlowCoordinator, to state: DescopeFlowState, from previous: DescopeFlowState)
    func coordinatorDidBecomeReady(_ coordinator: DescopeFlowCoordinator)
    func coordinatorDidInterceptNavigation(_ coordinator: DescopeFlowCoordinator, url: URL, external: Bool)
    func coordinatorDidFailAuthentication(_ coordinator: DescopeFlowCoordinator, error: DescopeError)
    func coordinatorDidFinishAuthentication(_ coordinator: DescopeFlowCoordinator, response: AuthenticationResponse)
}

/// A helper class for running Descope Flows.
///
/// You can create an instance of ``DescopeFlowCoordinator``, attach a `WKWebView` by
/// setting the ``webView`` property, and then call ``start(flow:)``. In almost any
/// situation though it would be more convenient to use a ``DescopeFlowViewController``
/// ot a ``DescopeFlowView`` instead.
@MainActor
public class DescopeFlowCoordinator {
    private let bridge: FlowBridge

    private var logger: DescopeLogger?

    public weak var delegate: DescopeFlowCoordinatorDelegate?

    public private(set) var state: DescopeFlowState = .initial {
        didSet {
            delegate?.coordinatorDidUpdateState(self, to: state, from: oldValue)
        }
    }

    public var webView: WKWebView? {
        didSet {
            bridge.webView = webView
        }
    }

    public init() {
        bridge = FlowBridge()
        bridge.delegate = self
    }

    public func prepare(configuration: WKWebViewConfiguration) {
        bridge.prepare(configuration: configuration)
    }

    // Flow

    private var flow: DescopeFlow? {
        didSet {
            oldValue?.resume = nil
            flow?.resume = resumeClosure
            logger = flow?.config.logger
            bridge.logger = logger
        }
    }

    public func start(flow: DescopeFlow) {
        logger(.info, "Starting flow authentication", flow)
        #if DEBUG
        precondition(flow.config.projectId != "", "The Descope singleton must be setup or an instance of DescopeSDK must be set on the flow")
        #endif

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

    private func handleFailure(_ error: Error) {
        guard ensureState(.started, .ready, .failed) else { return }

        // we allow multiple failure events and swallow them here instead of showing a warning above,
        // so that the bridge can just delegate any failures to the coordinator without having to
        // keep its own state to ensure it only reports a single failure
        guard state != .failed  else { return }

        if DescopeFlow.current === flow {
            DescopeFlow.current = nil
        }
        
        state = .failed
        let error = error as? DescopeError ?? DescopeError.flowFailed.with(cause: error)
        delegate?.coordinatorDidFailAuthentication(self, error: error)
    }

    private func handleReady() {
        guard ensureState(.started) else { return }
        bridge.set(oauthProvider: flow?.oauthProvider?.name, magicLinkRedirect: flow?.magicLinkRedirect?.absoluteString)
        state = .ready
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
            delegate?.coordinatorDidFinishAuthentication(self, response: authResponse)
        }
    }

    private func parseAuthentication(_ data: Data) async -> AuthenticationResponse? {
        do {
            var jwtResponse = try JSONDecoder().decode(DescopeClient.JWTResponse.self, from: data)
            try jwtResponse.setValues(from: data)
            let cookies = await webView?.configuration.websiteDataStore.httpCookieStore.allCookies() ?? []
            let projectId = flow?.config.projectId ?? ""
            jwtResponse.sessionJwt = try jwtResponse.sessionJwt?.isEmpty != false 
                ? findTokenCookie(named: DescopeClient.sessionCookieName, in: cookies, projectId: projectId) 
                : jwtResponse.sessionJwt
        
            jwtResponse.refreshJwt = try jwtResponse.refreshJwt?.isEmpty != false 
                ? findTokenCookie(named: DescopeClient.refreshCookieName, in: cookies, projectId: projectId) 
                : jwtResponse.refreshJwt
            return try jwtResponse.convert()
        } catch {
            logger(.error, "Unexpected error handling authentication response", error)
            handleFailure(error)
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
        // nothing
    }

    func bridgeDidFailLoading(_ bridge: FlowBridge, error: DescopeError) {
        handleFailure(error)
    }

    func bridgeDidFinishLoading(_ bridge: FlowBridge) {
        // nothing
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

private func findTokenCookie(named name: String, in cookies: [HTTPCookie], projectId: String) throws(DescopeError) -> String {
    // keep only cookies matching the required name
    let cookies = cookies.filter { name.caseInsensitiveCompare($0.name) == .orderedSame }
    guard !cookies.isEmpty else { throw DescopeError.decodeError.with(message: "Missing value in flow response \(name) cookie") }

    // try to make a deterministic choice between cookies by looking for the best matching token
    var tokens = cookies.compactMap { try? Token(jwt: $0.value) }
    guard !tokens.isEmpty else { throw DescopeError.decodeError.with(message: "Invalid value in flow response \(name) cookie") }

    // try to find the best match by prioritizing the newest non-expired token
    tokens = tokens.sorted { a, b in
        guard a.isExpired == b.isExpired else { return !a.isExpired }
        return a.issuedAt > b.issuedAt
    }

    // we expect the token to match the projectId
    tokens = tokens.filter { $0.projectId == projectId }
    guard let token = tokens.first else { throw DescopeError.decodeError.with(message: "Unexpected token issuer in flow response \(name) cookie") }

    return token.jwt
}

#endif
