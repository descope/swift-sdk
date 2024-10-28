
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
    func coordinatorDidFailAuthentication(_ coordinator: DescopeFlowCoordinator, error: DescopeError)
    func coordinatorDidFinishAuthentication(_ coordinator: DescopeFlowCoordinator, response: AuthenticationResponse)
}

@MainActor
public class DescopeFlowCoordinator {
    private let descope: DescopeSDK
    private let logger: DescopeLogger?
    private let bridge: FlowBridge

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

    public convenience init() {
        self.init(sdk: Descope.sdk)
    }

    public convenience init(using descope: DescopeSDK) {
        self.init(sdk: descope)
    }

    private init(sdk: DescopeSDK) {
        descope = sdk
        logger = sdk.config.logger
        bridge = FlowBridge()
        bridge.logger = logger
        bridge.delegate = self
    }

    public func prepare(configuration: WKWebViewConfiguration) {
        bridge.prepare(configuration: configuration)
    }

    public func start(flow: DescopeFlow) {
        logger(.info, "Starting flow authentication", flow)
        state = .started

        // dispatch this error asynchronously to prevent zalgo and let the calling function return
        guard let url = URL(string: flow.url) else {
            DispatchQueue.main.async { [self] in
                state = .failed
                delegate?.coordinatorDidFailLoading(self, error: DescopeError.flowFailed.with(message: "Invalid flow URL"))
            }
            return
        }

        let loadURL = { @MainActor [weak self, weak flow] url in
            var request = URLRequest(url: url)
            if let timeout = flow?.requestTimeoutInterval {
                request.timeoutInterval = timeout
            }
            self?.webView?.load(request)
        }

        flow.resume = loadURL

        loadURL(url)
    }

    // Authentication

    private func handleAuthentication(_ data: Data) {
        Task {
            logger(.info, "Finishing flow authentication")
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
            jwtResponse.sessionJwt = try jwtResponse.sessionJwt ?? findTokenCookie(named: DescopeClient.sessionCookieName, in: cookies, projectId: descope.config.projectId)
            jwtResponse.refreshJwt = try jwtResponse.refreshJwt ?? findTokenCookie(named: DescopeClient.refreshCookieName, in: cookies, projectId: descope.config.projectId)
            return try jwtResponse.convert()
        } catch let error as DescopeError {
            logger(.error, "Unexpected error converting authentication response", error)
            state = .failed
            delegate?.coordinatorDidFailAuthentication(self, error: error)
            return nil
        } catch {
            logger(.error, "Unexpected error parsing authentication response", error)
            state = .failed
            delegate?.coordinatorDidFailAuthentication(self, error: .flowFailed.with(cause: error))
            return nil
        }
    }

    // OAuth Native

    private func handleOAuthNative(clientId: String, stateId: String, nonce: String, implicit: Bool) {
        logger(.info, "Requesting authorization for Sign in with Apple", clientId)
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
            // TODO
        } catch {
            logger(.error, "Failed authenticating using Sign in with Apple", error)
            state = .failed
            delegate?.coordinatorDidFailAuthentication(self, error: error)
        }
    }

    // OAuth Web

    private func handleOAuthWeb(startURL: URL, finishURL: URL?) {
        logger(.info, "Requesting authorization for OAuth web", startURL)
        Task {
            await performOAuthWeb(startURL: startURL, finishURL: finishURL)
        }
    }

    private func performOAuthWeb(startURL: URL, finishURL: URL?) async {
        do {
            let exchangeCode = try await OAuth.performWebAuthentication(url: startURL, accessSharedUserData: true, logger: logger)
            let response = FlowBridgeResponse.oauthWeb(exchangeCode: exchangeCode)
            bridge.send(response: response)
        } catch .oauthWebCancelled {
            // TODO
        } catch {
            logger(.error, "Failed authenticating using OAuth web", error)
            state = .failed
            delegate?.coordinatorDidFailAuthentication(self, error: error)
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
        state = .ready
        delegate?.coordinatorDidBecomeReady(self)
    }

    func bridgeDidInterceptNavigation(_ bridge: FlowBridge, to url: URL, external: Bool) {
        // TODO
        UIApplication.shared.open(url)
    }

    func bridgeDidReceiveRequest(_ bridge: FlowBridge, request: FlowBridgeRequest) {
        switch request {
        case let .oauthNative(clientId, stateId, nonce, implicit):
            handleOAuthNative(clientId: clientId, stateId: stateId, nonce: nonce, implicit: implicit)
        case let .oauthWeb(startURL, finishURL):
            handleOAuthWeb(startURL: startURL, finishURL: finishURL)
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
