
import WebKit

public protocol DescopeFlowCoordinatorDelegate: AnyObject {
    func coordinatorFlowDidStartLoading(_ coordinator: DescopeFlowCoordinator)
    func coordinatorFlowDidFailLoading(_ coordinator: DescopeFlowCoordinator, error: DescopeError)
    func coordinatorFlowDidFinishLoading(_ coordinator: DescopeFlowCoordinator)
    func coordinatorFlowDidBecomeReady(_ coordinator: DescopeFlowCoordinator)
    func coordinatorFlowDidFailAuthentication(_ coordinator: DescopeFlowCoordinator, error: DescopeError)
    func coordinatorFlowDidFinishAuthentication(_ coordinator: DescopeFlowCoordinator, response: AuthenticationResponse)
}

@MainActor
public class DescopeFlowCoordinator {
    let descope: DescopeSDK
    let bridge: FlowBridge

    weak var delegate: DescopeFlowCoordinatorDelegate?

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
        bridge = FlowBridge()
        bridge.logger = sdk.config.logger
        bridge.delegate = self
    }

    public func prepare(configuration: WKWebViewConfiguration) {
        bridge.prepare(configuration: configuration)
    }

    public func start(runner: DescopeFlowRunner) {
        log(.info, "Starting flow authentication", runner.flowURL)
        let request = URLRequest(url: runner.flowURL)
        webView?.load(request)
    }

    // Actions

    private func handleAuthentication(_ data: Data) async {
        do {
            let cookies = await webView?.configuration.websiteDataStore.httpCookieStore.allCookies() ?? []
            var jwtResponse = try JSONDecoder().decode(DescopeClient.JWTResponse.self, from: data)
            try jwtResponse.setValues(from: data, cookies: cookies)
            let authResponse: AuthenticationResponse = try jwtResponse.convert()
            delegate?.coordinatorFlowDidFinishAuthentication(self, response: authResponse)
        } catch let error as DescopeError {
            log(.error, "Failed to parse authentication response", error)
            delegate?.coordinatorFlowDidFailAuthentication(self, error: error)
        } catch {
            log(.error, "Error parsing authentication response", error)
            delegate?.coordinatorFlowDidFailAuthentication(self, error: DescopeError.flowFailed.with(cause: error))
        }
    }
}

extension DescopeFlowCoordinator: FlowBridgeDelegate {
    func bridgeDidStartLoading(_ bridge: FlowBridge) {
        delegate?.coordinatorFlowDidStartLoading(self)
    }

    func bridgeDidFailLoading(_ bridge: FlowBridge, error: DescopeError) {
        delegate?.coordinatorFlowDidFailLoading(self, error: error)
    }

    func bridgeDidFinishLoading(_ bridge: FlowBridge) {
        delegate?.coordinatorFlowDidFinishLoading(self)
    }

    func bridgeDidBecomeReady(_ bridge: FlowBridge) {
        delegate?.coordinatorFlowDidBecomeReady(self)
    }

    func bridgeDidFailAuthentication(_ bridge: FlowBridge, error: DescopeError) {
        delegate?.coordinatorFlowDidFailAuthentication(self, error: error)
    }

    func bridgeDidFinishAuthentication(_ bridge: FlowBridge, data: Data) {
        Task {
            await handleAuthentication(data)
        }
    }
}

extension DescopeFlowCoordinator: LoggerProvider {
    var logger: DescopeLogger? {
        return descope.config.logger
    }
}
