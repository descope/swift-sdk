
import WebKit

@MainActor
protocol FlowBridgeDelegate: AnyObject {
    func bridgeDidStartLoading(_ bridge: FlowBridge)
    func bridgeDidFailLoading(_ bridge: FlowBridge, error: DescopeError)
    func bridgeDidFinishLoading(_ bridge: FlowBridge)
    func bridgeDidBecomeReady(_ bridge: FlowBridge)
//    func bridgeShouldShowScreen(_ bridge: FlowBridge, screenId: String) -> Bool
//    func bridgeDidShowScreen(_ bridge: FlowBridge, screenId: String)
    func bridgeDidInterceptNavigation(_ bridge: FlowBridge, url: URL, external: Bool)
    func bridgeDidReceiveRequest(_ bridge: FlowBridge, request: FlowBridgeRequest)
    func bridgeDidFailAuthentication(_ bridge: FlowBridge, error: DescopeError)
    func bridgeDidFinishAuthentication(_ bridge: FlowBridge, data: Data)
}

enum FlowBridgeRequest {
    case oauthNative(clientId: String, stateId: String, nonce: String, implicit: Bool)
    case webAuth(variant: String, startURL: URL, finishURL: URL?)
    case beforeScreen(screenId: String)
    case afterScreen(screenId: String)
}

enum FlowBridgeResponse {
    case oauthNative(stateId: String, authorizationCode: String?, identityToken: String?, user: String?)
    case webAuth(variant: String, exchangeCode: String)
    case magicLink(url: String)
    case beforeScreen(override: Bool)
    case resumeScreen(interactionId: String, form: [String: Any])
    case failure(String)
}

@MainActor
class FlowBridge: NSObject {
    /// The coordinator sets a logger automatically.
    var logger: DescopeLogger?

    /// The coordinator sets itself as the bridge delegate.
    weak var delegate: FlowBridgeDelegate?

    /// This property is weak since the bridge is not considered the "owner" of the webview, and in
    /// addition, it helps prevent retain cycles as the webview itself retains the bridge when the
    /// latter is added as a scriptMessageHandler to the webview configuration.
    weak var webView: WKWebView? {
        willSet {
            webView?.navigationDelegate = nil
            webView?.uiDelegate = nil
        }
        didSet {
            webView?.navigationDelegate = self
            webView?.uiDelegate = self
        }
    }

    /// Injects the JavaScript code below that's required for the bridge to work, as well as
    /// handlers for messages sent from the webpage to the bridge.
    func prepare(configuration: WKWebViewConfiguration) {
        let setup = WKUserScript(source: setupScript, injectionTime: .atDocumentStart, forMainFrameOnly: false)
        configuration.userContentController.addUserScript(setup)

        let initialize = WKUserScript(source: initScript, injectionTime: .atDocumentEnd, forMainFrameOnly: false)
        configuration.userContentController.addUserScript(initialize)

        if #available(iOS 17.0, macOS 14.0, *) {
            configuration.preferences.inactiveSchedulingPolicy = .none
        }

        for name in FlowBridgeMessage.allCases {
            configuration.userContentController.add(self, name: name.rawValue)
        }
    }
}

extension FlowBridge {
    /// Called by the coordinator once the flow is ready to configure native specific options
    func set(oauthProvider: String?, magicLinkRedirect: String?) {
        call(function: "set", params: oauthProvider ?? "", magicLinkRedirect ?? "")
    }

    /// Called by the coordinator when it's done handling a bridge request
    func send(response: FlowBridgeResponse) {
        call(function: "send", params: response.type, response.payload)
    }

    /// Helper method to run one of the namespaced functions with escaped string parameters
    private func call(function: String, params: String...) {
        let escaped = params.map { $0.javaScriptLiteralString() }.joined(separator: ", ")
        let javascript = "\(namespace)_\(function)(\(escaped))"
        webView?.evaluateJavaScript(javascript)
    }
}

extension FlowBridge: WKScriptMessageHandler {
    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        switch FlowBridgeMessage(rawValue: message.name) {
        case .log:
            #if DEBUG
            if let json = message.body as? [String: Any], let tag = json["tag"] as? String, let message = json["message"] as? String {
                logger(.debug, "Webview console", "\(tag): \(message)")
            }
            #endif
        case .ready:
            logger(.info, "Bridge received ready event", message.body)
            delegate?.bridgeDidBecomeReady(self)
        case .bridge:
            logger(.info, "Bridge received native event")
            guard let json = message.body as? [String: Any], let request = FlowBridgeRequest(json: json) else {
                logger(.error, "Invalid JSON data in flow native event", message.body)
                delegate?.bridgeDidFailAuthentication(self, error: DescopeError.flowFailed.with(message: "Invalid JSON data in flow native event"))
                return
            }
            delegate?.bridgeDidReceiveRequest(self, request: request)
        case .failure:
            logger(.error, "Bridge received failure event", message.body)
            if let dict = message.body as? [String: Any], let error = DescopeError(errorResponse: dict) {
                delegate?.bridgeDidFailAuthentication(self, error: error)
            } else {
                delegate?.bridgeDidFailAuthentication(self, error: DescopeError.flowFailed.with(message: "Unexpected authentication failure"))
            }
        case .success:
            logger(.info, "Bridge received success event")
            guard let json = message.body as? String, case let data = Data(json.utf8) else {
                logger(.error, "Invalid JSON data in flow success event", message.body)
                delegate?.bridgeDidFailAuthentication(self, error: DescopeError.flowFailed.with(message: "Invalid JSON data in flow success event"))
                return
            }
            delegate?.bridgeDidFinishAuthentication(self, data: data)
        case nil:
            logger(.error, "Bridge received unexpected message", message.name)
        }
    }
}

extension FlowBridge: WKNavigationDelegate {
    func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction) async -> WKNavigationActionPolicy {
        switch navigationAction.navigationType {
        case .linkActivated:
            logger(.info, "Webview intercepted link", navigationAction.request.url?.absoluteString)
            if let url = navigationAction.request.url {
                delegate?.bridgeDidInterceptNavigation(self, url: url, external: false)
            }
            return .cancel
        default:
            logger(.info, "Webview will load url", navigationAction.navigationType == .other ? nil : "type=\(navigationAction.navigationType.rawValue)", navigationAction.request.url?.absoluteString)
            return .allow
        }
    }

    func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation) {
        logger(.info, "Webview started loading webpage")
        delegate?.bridgeDidStartLoading(self)
    }

    func webView(_ webView: WKWebView, didReceiveServerRedirectForProvisionalNavigation navigation: WKNavigation) {
        logger(.info, "Webview received server redirect", webView.url)
    }

    func webView(_ webView: WKWebView, decidePolicyFor navigationResponse: WKNavigationResponse) async -> WKNavigationResponsePolicy {
        if let response = navigationResponse.response as? HTTPURLResponse, let error = HTTPError(statusCode: response.statusCode) {
            logger(.error, "Webview failed loading page", error)
            delegate?.bridgeDidFailLoading(self, error: DescopeError.networkError.with(message: error.description))
            return .cancel
        }
        logger(.info, "Webview will receive response")
        return .allow
    }

    func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation, withError error: Error) {
        // Don't print an error log if this was triggered by a non-2xx status code that was caught
        // above and causing the delegate function to return `.cancel`. We rely on the coordinator
        // to not notify about errors multiple times.
        if case let error = error as NSError, error.domain == "WebKitErrorDomain", error.code == 102 { // https://chromium.googlesource.com/chromium/src/+/2233628f5f5b32c7b458428f8d5cfbd0a18be82e/ios/web/public/web_kit_constants.h#25
            logger(.info, "Webview loading was cancelled")
        } else {
            logger(.error, "Webview failed loading url", error)
        }
        delegate?.bridgeDidFailLoading(self, error: DescopeError.networkError.with(cause: error))
    }

    func webView(_ webView: WKWebView, didCommit navigation: WKNavigation) {
        logger(.info, "Webview received response")
    }

    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation) {
        logger(.info, "Webview finished loading webpage")
        delegate?.bridgeDidFinishLoading(self)
    }

    func webView(_ webView: WKWebView, didFail navigation: WKNavigation, withError error: Error) {
        logger(.error, "Webview failed loading webpage", error)
        delegate?.bridgeDidFailLoading(self, error: DescopeError.networkError.with(cause: error))
    }
}

extension FlowBridge: WKUIDelegate {
    func webView(_ webView: WKWebView, createWebViewWith configuration: WKWebViewConfiguration, for navigationAction: WKNavigationAction, windowFeatures: WKWindowFeatures) -> WKWebView? {
        logger(.info, "Webview intercepted external link", navigationAction.request.url?.absoluteString)
        if let url = navigationAction.request.url {
            delegate?.bridgeDidInterceptNavigation(self, url: url, external: true)
        }
        return nil
    }
}

extension FlowBridge {
    func addStyles(_ css: String) {
        runJavaScript("""
            const styles = \(css.javaScriptLiteralString())
            const element = document.createElement('style')
            element.textContent = styles
            document.head.appendChild(element)
        """)
    }

    func runJavaScript(_ code: String) {
        let javascript = anonymousFunction(body: code)
        webView?.evaluateJavaScript(javascript)
    }

    private func anonymousFunction(body: String) -> String {
        return """
            (function() {
                \(body)
            })()
        """
    }
}

private enum FlowBridgeMessage: String, CaseIterable {
    case log, ready, bridge, failure, success
}

private extension FlowBridgeRequest {
    init?(json: [String: Any]) {
        guard let payload = json["payload"] as? [String: Any] else { return nil }
        let type = json["type"] as? String ?? ""
        switch type {
        case "oauthNative":
            guard let start = payload["start"] as? [String: Any] else { return nil }
            guard let clientId = start["clientId"] as? String, let stateId = start["stateId"] as? String, let nonce = start["nonce"] as? String, let implicit = start["implicit"] as? Bool else { return nil }
            self = .oauthNative(clientId: clientId, stateId: stateId, nonce: nonce, implicit: implicit)
        case "oauthWeb", "sso":
            guard let startString = payload["startUrl"] as? String, let startURL = URL(string: startString) else { return nil }
            var finishURL: URL?
            if let str = payload["finishUrl"] as? String, !str.isEmpty, let url = URL(string: str) {
                finishURL = url
            }
            self = .webAuth(variant: type, startURL: startURL, finishURL: finishURL)
        case "beforeScreen":
            guard let screenId = payload["screenId"] as? String else { return nil }
            self = .beforeScreen(screenId: screenId)
        case "afterScreen":
            guard let screenId = payload["screenId"] as? String else { return nil }
            self = .afterScreen(screenId: screenId)
        default:
            return nil
        }
    }
}

private extension FlowBridgeResponse {
    var type: String {
        switch self {
        case .oauthNative: return "oauthNative"
        case .webAuth(let variant, _): return variant
        case .magicLink: return "magicLink"
        case .beforeScreen: return "beforeScreen"
        case .resumeScreen: return "resumeScreen"
        case .failure: return "failure"
        }
    }

    var payload: String {
        guard let json = try? JSONSerialization.data(withJSONObject: payloadDictionary), let str = String(bytes: json, encoding: .utf8) else { return "{}" }
        return str
    }

    private var payloadDictionary: [String: Any] {
        switch self {
        case let .oauthNative(stateId, authorizationCode, identityToken, user):
            var nativeOAuth: [String: Any] = [:]
            nativeOAuth["stateId"] = stateId
            if let authorizationCode {
                nativeOAuth["code"] = authorizationCode
            }
            if let identityToken {
                nativeOAuth["idToken"] = identityToken
            }
            if let user {
                nativeOAuth["user"] = user
            }
            return [
                "nativeOAuth": nativeOAuth,
            ]
        case let .webAuth(_, exchangeCode):
            return [
                "exchangeCode": exchangeCode,
            ]
        case let .magicLink(url):
            return [
                "url": url
            ]
        case let .beforeScreen(override):
            return [
                "override": override
            ]
        case let .resumeScreen(interactionId, form):
            return [
                "interactionId": interactionId,
                "form": form,
            ]
        case let .failure(failure):
            return [
                "failure": failure
            ]
        }
    }
}

/// A namespace used to prevent collisions with symbols in the JavaScript page
private let namespace = "_Descope_Bridge"

/// Connects the bridge to the web view and prepares the Descope web-component
private let setupScript = """

// Signal to other subsystems that they're running inside a bridge-enabled webview 
window.IsDescopeBridge = true

// Redirect console to bridge
window.console.log = (s) => { window.webkit.messageHandlers.\(FlowBridgeMessage.log.rawValue).postMessage({ tag: 'log', message: s }) }
window.console.debug = (s) => { window.webkit.messageHandlers.\(FlowBridgeMessage.log.rawValue).postMessage({ tag: 'debug', message: s }) }
window.console.info = (s) => { window.webkit.messageHandlers.\(FlowBridgeMessage.log.rawValue).postMessage({ tag: 'info', message: s }) }
window.console.warn = (s) => { window.webkit.messageHandlers.\(FlowBridgeMessage.log.rawValue).postMessage({ tag: 'warn', message: s }) }
window.console.error = (s) => { window.webkit.messageHandlers.\(FlowBridgeMessage.log.rawValue).postMessage({ tag: 'error', message: s }) }
window.onerror = (message, source, line, column, error) => { window.webkit.messageHandlers.\(FlowBridgeMessage.log.rawValue).postMessage({ tag: 'fail', message: `${message}, ${source || '-'}, ${error || '-'}` }) }

"""

private let initScript = """

// Called directly below
function \(namespace)_initialize() {
    let interval

    let component = \(namespace)_find()
    if (component) {
        \(namespace)_prepare(component)
        return
    }

    interval = setInterval(() => {
        let component = \(namespace)_find()
        if (component) {
            clearInterval(interval)
            \(namespace)_prepare(component)
        }
    }, 20)
}

// Finds the Descope web-component in the webpage
function \(namespace)_find() {
    return document.querySelector('descope-wc')
}

// Attaches event listeners once the Descope web-component is found
function \(namespace)_prepare(component) {
    component.nativeOptions = {
        platform: 'ios',
        bridgeVersion: 1,
        oauthRedirect: '\(WebAuth.redirectURL)',
        ssoRedirect: '\(WebAuth.redirectURL)',
    }

    if (component.flowStatus === 'error') {
        window.webkit.messageHandlers.\(FlowBridgeMessage.failure.rawValue).postMessage('The flow failed during initialization')
    } else if (component.flowStatus === 'ready' || component.shadowRoot?.querySelector('descope-container')) {
        \(namespace)_ready(component, 'immediate')
    } else {
        component.addEventListener('ready', () => {
            \(namespace)_ready(component, 'listener')
        })
    }

    component.addEventListener('bridge', (event) => {
        window.webkit.messageHandlers.\(FlowBridgeMessage.bridge.rawValue).postMessage(event.detail)
    })

    component.addEventListener('error', (event) => {
        window.webkit.messageHandlers.\(FlowBridgeMessage.failure.rawValue).postMessage(event.detail)
    })

    component.addEventListener('success', (event) => {
        window.webkit.messageHandlers.\(FlowBridgeMessage.success.rawValue).postMessage(JSON.stringify(event.detail))
    })

    component.addEventListener('page-updated', (event) => {
        window.webkit.messageHandlers.\(FlowBridgeMessage.bridge.rawValue).postMessage({
            type: 'afterScreen',
            payload: {
                screenId: 'todo',
            },
        })
    })

    const previousPageUpdate = component.onPageUpdate
    component.onPageUpdate = async (state, ref) => {
        const promise = new Promise((resolve, reject) => {
            console.log(`onPageUpdate: ${JSON.stringify(state)}`)
            window.webkit.messageHandlers.\(FlowBridgeMessage.bridge.rawValue).postMessage({
                type: 'beforeScreen',
                payload: {
                    screenId: state.screenId,
                },
            })
            component.pendingNext = state.next
            component.pendingResolve = resolve
        })
        const shouldOverride = await promise
        if (!shouldOverride && previousPageUpdate) {
            return await previousPageUpdate(state, ref)
        }
        return shouldOverride
    }

    component.lazyInit()
}

// Called when the Descope web-component is ready to notify the bridge
function \(namespace)_ready(component, tag) {
    if (!component.bridgeVersion) {
        window.webkit.messageHandlers.\(FlowBridgeMessage.failure.rawValue).postMessage('The flow is using an unsupported web component version')
    } else {
        window.webkit.messageHandlers.\(FlowBridgeMessage.ready.rawValue).postMessage(tag)
    }
}

// Updates the values of native options
function \(namespace)_set(oauthProvider, magicLinkRedirect) {
    let component = \(namespace)_find()
    if (component) {
        component.nativeOptions.oauthProvider = oauthProvider
        component.nativeOptions.magicLinkRedirect = magicLinkRedirect
    }
}

// Sends a response from the bridge to resume the flow
function \(namespace)_send(type, payload) {
    let component = \(namespace)_find()
    if (component) {
        if (type === 'beforeScreen') {
            const json = JSON.parse(payload)
            const resolve = component.pendingResolve
            component.pendingResolve = null
            if (!json.override) {
                component.pendingNext = null
            }
            resolve(json.override)
        } else if (type === 'resumeScreen') {
            console.log(`resume: ${payload}`)
            const json = JSON.parse(payload)
            const next = component.pendingNext
            component.pendingNext = null
            next(json.interactionId, json.form)
        } else {
            component.nativeResume(type, payload)
        }
    }
}

// Performs required initializations on the page and waits for the web-component to be available
\(namespace)_initialize()

"""
