
#if os(iOS)

import UIKit
import WebKit

@MainActor
public protocol DescopeFlowCoordinatorDelegate: AnyObject {
    func coordinatorDidUpdateState(_ coordinator: DescopeFlowCoordinator, to state: DescopeFlowState, from previous: DescopeFlowState)
    func coordinatorDidStartLoading(_ coordinator: DescopeFlowCoordinator)
    func coordinatorDidFailLoading(_ coordinator: DescopeFlowCoordinator, error: DescopeError)
    func coordinatorDidFinishLoading(_ coordinator: DescopeFlowCoordinator)
    func coordinatorDidBecomeReady(_ coordinator: DescopeFlowCoordinator)
    func coordinatorDidInterceptNavigation(_ coordinator: DescopeFlowCoordinator, to url: URL, external: Bool)
    func coordinatorDidFailAuthentication(_ coordinator: DescopeFlowCoordinator, error: DescopeError)
    func coordinatorDidFinishAuthentication(_ coordinator: DescopeFlowCoordinator, response: AuthenticationResponse)
}

@MainActor
public class DescopeFlowCoordinator {
    private let bridge: FlowBridge

    private var logger: DescopeLogger?

    public weak var delegate: DescopeFlowCoordinatorDelegate?

    public private(set) var state: DescopeFlowState = .initial {
        didSet {
            if state == .failed || state == .finished, DescopeFlow.current === flow {
                DescopeFlow.current = nil
            }
            delegate?.coordinatorDidUpdateState(self, to: state, from: oldValue)
        }
    }

    private var flow: DescopeFlow? {
        didSet {
            logger = flow?.descope.config.logger
            bridge.logger = logger
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

    public func start(flow: DescopeFlow) {
        self.flow = flow
        DescopeFlow.current = flow

        logger(.info, "Starting flow authentication", flow)
        state = .started

        flow.resume = makeFlowResumeClosure(for: self)

        load(url: flow.url, for: flow)
    }

    fileprivate func load(url: URL, for flow: DescopeFlow) {
        var request = URLRequest(url: url)
        if let timeout = flow.requestTimeoutInterval {
            request.timeoutInterval = timeout
        }
        webView?.load(request)
    }

    // Authentication

    private func handleAuthentication(_ data: Data) {
        logger(.info, "Finishing flow authentication")
        Task {
            guard let authResponse = await parseAuthentication(data) else { return }
            state = .finished
            delegate?.coordinatorDidFinishAuthentication(self, response: authResponse)
        }
    }

    private func parseAuthentication(_ data: Data) async -> AuthenticationResponse? {
        do {
            var jwtResponse = try JSONDecoder().decode(DescopeClient.JWTResponse.self, from: data)
            try jwtResponse.setValues(from: data)
            let cookies = await webView?.configuration.websiteDataStore.httpCookieStore.allCookies() ?? []
            let projectId = flow?.descope.config.projectId ?? ""
            jwtResponse.sessionJwt = try jwtResponse.sessionJwt ?? findTokenCookie(named: DescopeClient.sessionCookieName, in: cookies, projectId: projectId)
            jwtResponse.refreshJwt = try jwtResponse.refreshJwt ?? findTokenCookie(named: DescopeClient.refreshCookieName, in: cookies, projectId: projectId)
            return try jwtResponse.convert()
        } catch let error as DescopeError {
            logger(.error, "Unexpected error converting authentication response", error)
            state = .failed
            delegate?.coordinatorDidFailAuthentication(self, error: error)
            return nil
        } catch {
            logger(.error, "Unexpected error parsing authentication response", error)
            state = .failed
            delegate?.coordinatorDidFailAuthentication(self, error: DescopeError.flowFailed.with(cause: error))
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
            let response = FlowBridgeResponse.oauthNative(stateId: stateId, authorizationCode: authorizationCode, identityToken: identityToken, user: user)
            bridge.send(response: response)
        } catch .oauthNativeCancelled {
            bridge.send(response: .failure("OAuthNativeCancelled"))
        } catch {
            bridge.send(response: .failure("OAuthNativeFailed"))
        }
    }

    // OAuth / SSO

    private func handleWebAuth(startURL: URL, finishURL: URL?) {
        logger(.info, "Requesting web authentication", startURL)
        Task {
            await performWebAuth(startURL: startURL, finishURL: finishURL)
        }
    }

    private func performWebAuth(startURL: URL, finishURL: URL?) async {
        do {
            let exchangeCode = try await WebAuth.performAuthentication(url: startURL, accessSharedUserData: true, logger: logger)
            let response = FlowBridgeResponse.webAuth(exchangeCode: exchangeCode)
            bridge.send(response: response)
        } catch .webAuthCancelled {
            bridge.send(response: .failure("WebAuthCancelled"))
        } catch {
            bridge.send(response: .failure("WebAuthFailed"))
        }
    }
}

extension DescopeFlowCoordinator: FlowBridgeDelegate {
    func bridgeDidStartLoading(_ bridge: FlowBridge) {
        delegate?.coordinatorDidStartLoading(self)
    }

    func bridgeDidFailLoading(_ bridge: FlowBridge, error: DescopeError) {
        state = .failed
        delegate?.coordinatorDidFailLoading(self, error: error)
    }

    func bridgeDidFinishLoading(_ bridge: FlowBridge) {
        delegate?.coordinatorDidFinishLoading(self)
    }

    func bridgeDidBecomeReady(_ bridge: FlowBridge) {
        bridge.set(oauthProvider: flow?.oauthProvider?.name, magicLinkRedirect: flow?.magicLinkRedirect?.absoluteString)
        state = .ready
        delegate?.coordinatorDidBecomeReady(self)
    }

    func bridgeDidInterceptNavigation(_ bridge: FlowBridge, to url: URL, external: Bool) {
        delegate?.coordinatorDidInterceptNavigation(self, to: url, external: external)
    }

    func bridgeDidReceiveRequest(_ bridge: FlowBridge, request: FlowBridgeRequest) {
        switch request {
        case let .oauthNative(clientId, stateId, nonce, implicit):
            handleOAuthNative(clientId: clientId, stateId: stateId, nonce: nonce, implicit: implicit)
        case let .webAuth(startURL, finishURL):
            handleWebAuth(startURL: startURL, finishURL: finishURL)
        }
    }

    func bridgeDidFailAuthentication(_ bridge: FlowBridge, error: DescopeError) {
        state = .failed
        delegate?.coordinatorDidFailAuthentication(self, error: error)
    }

    func bridgeDidFinishAuthentication(_ bridge: FlowBridge, data: Data) {
        handleAuthentication(data)
    }
}

#endif

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

private func makeFlowResumeClosure(for coordinator: DescopeFlowCoordinator) -> DescopeFlow.ResumeClosure {
    return { @MainActor [weak coordinator] flow, url in
        coordinator?.load(url: url, for: flow)
    }
}
