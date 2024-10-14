
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
    private let log: DescopeLogger?
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
        log = sdk.config.logger
        bridge = FlowBridge()
        bridge.log = log
        bridge.delegate = self
    }

    public func prepare(configuration: WKWebViewConfiguration) {
        bridge.prepare(configuration: configuration)
    }

    public func start(runner: DescopeFlowRunner) {
        log(.info, "Starting flow authentication", runner.flowURL)
        state = .started
        let request = URLRequest(url: runner.flowURL)
        webView?.load(request)
    }

    // Authentication

    private func handleAuthentication(_ data: Data) {
        Task {
            log(.info, "Finishing flow authentication")
            guard let authResponse = await parseAuthentication(data) else { return }
            state = .finished
            delegate?.coordinatorDidFinishAuthentication(self, response: authResponse)
        }
    }

    private func parseAuthentication(_ data: Data) async -> AuthenticationResponse? {
        do {
            let cookies = await webView?.configuration.websiteDataStore.httpCookieStore.allCookies() ?? []
            var jwtResponse = try JSONDecoder().decode(DescopeClient.JWTResponse.self, from: data)
            try jwtResponse.setValues(from: data, cookies: cookies)
            return try jwtResponse.convert()
        } catch let error as DescopeError {
            log(.error, "Unexpected error converting authentication response", error)
            state = .failed
            delegate?.coordinatorDidFailAuthentication(self, error: error)
            return nil
        } catch {
            log(.error, "Unexpected error parsing authentication response", error)
            state = .failed
            delegate?.coordinatorDidFailAuthentication(self, error: DescopeError.flowFailed.with(cause: error))
            return nil
        }
    }

    // OAuth

    private func handleOAuthNative(clientId: String, stateId: String, nonce: String, implicit: Bool) {
        log(.info, "Requesting authorization for Sign in with Apple", clientId)
        Task {
            await performOAuthNative(stateId: stateId, nonce: nonce, implicit: implicit)
        }
    }

    private func performOAuthNative(stateId: String, nonce: String, implicit: Bool) async {
        do {
            let (authorizationCode, identityToken, user) = try await OAuth.performNativeAuthorization(nonce: nonce, implicit: implicit, log: log)
            let response = FlowBridgeResponse.oauthNative(stateId: stateId, authorizationCode: authorizationCode, identityToken: identityToken, user: user)
            bridge.send(response: response)
        } catch .flowCancelled {
            // TODO
        } catch {
            log(.error, "Failed authenticating using Sign in with Apple", error)
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

    func bridgeDidReceiveRequest(_ bridge: FlowBridge, request: FlowBridgeRequest) {
        switch request {
        case let .oauthNative(clientId, stateId, nonce, implicit):
            handleOAuthNative(clientId: clientId, stateId: stateId, nonce: nonce, implicit: implicit)
        case .oauthWeb:
            break // TODO
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
