
#if os(iOS)

import UIKit
import WebKit

@MainActor
protocol FlowBridgeDelegate: AnyObject {
    func bridgeDidStartLoading(_ bridge: FlowBridge)
    func bridgeDidFailLoading(_ bridge: FlowBridge, error: DescopeError)
    func bridgeDidFinishLoading(_ bridge: FlowBridge)
    func bridgeDidBecomeReady(_ bridge: FlowBridge)
    func bridgeDidInterceptNavigation(_ bridge: FlowBridge, to url: URL, external: Bool)
    func bridgeDidReceiveRequest(_ bridge: FlowBridge, request: FlowBridgeRequest)
    func bridgeDidFailAuthentication(_ bridge: FlowBridge, error: DescopeError)
    func bridgeDidFinishAuthentication(_ bridge: FlowBridge, data: Data)
}

enum FlowBridgeRequest {
    case oauthNative(clientId: String, stateId: String, nonce: String, implicit: Bool)
    case webAuth(startURL: URL, finishURL: URL?)
}

enum FlowBridgeResponse {
    case oauthNative(stateId: String, authorizationCode: String?, identityToken: String?, user: String?)
    case webAuth(exchangeCode: String)
    case failure(String)
}

@MainActor
class FlowBridge: NSObject {
    var logger: DescopeLogger? = Descope.sdk.config.logger

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

    func prepare(configuration: WKWebViewConfiguration) {
        let setup = WKUserScript(source: setupScript, injectionTime: .atDocumentStart, forMainFrameOnly: false)
        configuration.userContentController.addUserScript(setup)
        if #available(iOS 17.0, *) {
            configuration.preferences.inactiveSchedulingPolicy = .none
        }

        for name in FlowBridgeMessage.allCases {
            configuration.userContentController.add(self, name: name.rawValue)
        }
    }

    func send(response: FlowBridgeResponse) {
        webView?.callJavaScript(function: "send", params: response.stringValue)
    }

    func set(oauthProvider: String?, magicLinkRedirect: String?) {
        webView?.callJavaScript(function: "set", params: oauthProvider ?? "", magicLinkRedirect ?? "")
    }
}

extension FlowBridge: WKScriptMessageHandler {
    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        switch FlowBridgeMessage(rawValue: message.name) {
        case .log:
            #if DEBUG
            if let json = message.body as? [String: Any], let tag = json["tag"] as? String, let message = json["message"] as? String {
                logger(.debug, "Console", "\(tag): \(message)")
            }
            #endif
        case .ready:
            logger(.info, "Bridge received ready event")
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
            delegate?.bridgeDidFailAuthentication(self, error: DescopeError.flowFailed.with(message: "Unexpected authentication failure [\(message.body)]"))
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
                delegate?.bridgeDidInterceptNavigation(self, to: url, external: false)
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
        logger(.info, "Webview will receive response")
        return .allow
    }

    func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation, withError error: Error) {
        logger(.error, "Webview failed loading url", error)
        delegate?.bridgeDidFailLoading(self, error: DescopeError.networkError.with(cause: error))
    }

    func webView(_ webView: WKWebView, didCommit navigation: WKNavigation) {
        logger(.info, "Webview received response")
    }

    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation) {
        logger(.info, "Webview finished loading webpage")
        delegate?.bridgeDidFinishLoading(self)
        webView.callJavaScript(function: "wait")
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
            delegate?.bridgeDidInterceptNavigation(self, to: url, external: true)
        }
        return nil
    }
}

private enum FlowBridgeMessage: String, CaseIterable {
    case log, ready, bridge, failure, success
}

private extension FlowBridgeRequest {
    init?(json: [String: Any]) {
        guard let payload = json["payload"] as? [String: Any] else { return nil }
        switch json["type"] as? String {
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
            self = .webAuth(startURL: startURL, finishURL: finishURL)
        default:
            return nil
        }
    }
}

private extension FlowBridgeResponse {
    var dictionaryValue: [String: Any] {
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
        case let .webAuth(exchangeCode):
            return [
                "exchangeCode": exchangeCode,
                "idpInitiated": true,
            ]
        case let .failure(failure):
            return [
                "failure": failure,
            ]
        }
    }

    var stringValue: String {
        guard let json = try? JSONSerialization.data(withJSONObject: dictionaryValue), let str = String(bytes: json, encoding: .utf8) else { return "{}" }
        return str
    }
}

private extension WKWebView {
    func callJavaScript(function: String, params: String...) {
        let escaped = params.map(escapeWithBackticks).joined(separator: ", ")
        let javascript = "\(namespace)_\(function)(\(escaped))"
        evaluateJavaScript(javascript)
    }

    private func escapeWithBackticks(_ str: String) -> String {
        return "`" + str.replacingOccurrences(of: #"\"#, with: #"\\"#)
            .replacingOccurrences(of: #"$"#, with: #"\$"#)
            .replacingOccurrences(of: #"`"#, with: #"\`"#) + "`"
    }
}

private let namespace = "_Descope_Bridge"

private let setupScript = """

// Redirect console to bridge
window.console.log = (s) => { window.webkit.messageHandlers.\(FlowBridgeMessage.log.rawValue).postMessage({ tag: 'log', message: s }) }
window.console.debug = (s) => { window.webkit.messageHandlers.\(FlowBridgeMessage.log.rawValue).postMessage({ tag: 'debug', message: s }) }
window.console.info = (s) => { window.webkit.messageHandlers.\(FlowBridgeMessage.log.rawValue).postMessage({ tag: 'info', message: s }) }
window.console.warn = (s) => { window.webkit.messageHandlers.\(FlowBridgeMessage.log.rawValue).postMessage({ tag: 'warn', message: s }) }
window.console.error = (s) => { window.webkit.messageHandlers.\(FlowBridgeMessage.log.rawValue).postMessage({ tag: 'error', message: s }) }

// Finds the Descope web-component in the webpage
function \(namespace)_find() {
    return document.getElementsByTagName('descope-wc')[0]
}

// Called by bridge when the WebView finished loading
function \(namespace)_wait() {
    const styles = `
        * {
          -webkit-touch-callout: none;
          -webkit-user-select: none;
        }
    `

    const stylesheet = document.createElement("style")
    stylesheet.textContent = styles
    document.head.appendChild(stylesheet)

    let interval
    interval = setInterval(() => {
        let component = \(namespace)_find()
        if (component) {
            clearInterval(interval)
            \(namespace)_prepare(component)
        }
    }, 20)
}

// Attaches event listeners once the Descope web-component is ready
function \(namespace)_prepare(component) {
    component.nativeOptions = {
        platform: 'ios',
        bridgeVersion: 1,
        oauthRedirect: '\(WebAuth.redirectURL)',
        ssoRedirect: '\(WebAuth.redirectURL)',
    }

    component.addEventListener('ready', () => {
        if (!component.bridgeVersion) {
            window.webkit.messageHandlers.\(FlowBridgeMessage.failure.rawValue).postMessage('The flow is using an unsupported web component version')
        } else {
            window.webkit.messageHandlers.\(FlowBridgeMessage.ready.rawValue).postMessage('')
        }
    })

    component.addEventListener('bridge', (event) => {
        window.webkit.messageHandlers.\(FlowBridgeMessage.bridge.rawValue).postMessage(event.detail)
    })

    component.addEventListener('error', (event) => {
        window.webkit.messageHandlers.\(FlowBridgeMessage.failure.rawValue).postMessage(event.detail)
    })

    component.addEventListener('success', (event) => {
        window.webkit.messageHandlers.\(FlowBridgeMessage.success.rawValue).postMessage(JSON.stringify(event.detail))
    })
}

// Updates the values of native options
function \(namespace)_set(oauthProvider, magicLinkRedirect) {
    let component = \(namespace)_find()
    if (component) {
        component.nativeOptions.oauthProvider = oauthProvider
        component.nativeOptions.magicLinkRedirect = magicLinkRedirect
    }
}

// Sends a response from the bridge to complete a native request
function \(namespace)_send(response) {
    let component = \(namespace)_find()
    if (component) {
        component.nativeComplete(response)
    }
}

"""

#endif
