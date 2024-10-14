
#if os(iOS)

import UIKit
import WebKit

@MainActor
protocol FlowBridgeDelegate: AnyObject {
    func bridgeDidStartLoading(_ bridge: FlowBridge)
    func bridgeDidFailLoading(_ bridge: FlowBridge, error: DescopeError)
    func bridgeDidFinishLoading(_ bridge: FlowBridge)
    func bridgeDidBecomeReady(_ bridge: FlowBridge)
    func bridgeDidReceiveRequest(_ bridge: FlowBridge, request: FlowBridgeRequest)
    func bridgeDidFailAuthentication(_ bridge: FlowBridge, error: DescopeError)
    func bridgeDidFinishAuthentication(_ bridge: FlowBridge, data: Data)
}

enum FlowBridgeRequest {
    case oauthNative(clientId: String, stateId: String, nonce: String, implicit: Bool)
    case oauthWeb(url: String, defaultProvider: String?)
}

enum FlowBridgeResponse {
    case oauthNative(stateId: String, authorizationCode: String?, identityToken: String?, user: String?)
}

@MainActor
class FlowBridge: NSObject {
    var log: DescopeLogger? = Descope.sdk.config.logger

    weak var delegate: FlowBridgeDelegate?

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
        if #available(iOS 14.5, *) {
            configuration.preferences.isTextInteractionEnabled = false
        }
        if #available(iOS 17.0, *) {
            configuration.preferences.inactiveSchedulingPolicy = .none
        }

        for name in FlowBridgeMessage.allCases {
            configuration.userContentController.add(self, name: name.rawValue)
        }
    }

    func send(response: FlowBridgeResponse) {
        webView?.evaluateJavaScript("""
            let component = findWebComponent()
            if (component) {
                component.nativeComplete(`\(response.stringValue)`)
            }
        """)
    }
}

extension FlowBridge: WKScriptMessageHandler {
    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        switch FlowBridgeMessage(rawValue: message.name) {
        case .log:
            log(.debug, "Console Log", message.body)
        case .warn:
            log(.debug, "Console Warn", message.body)
        case .error:
            log(.debug, "Console Error", message.body)
        case .ready:
            log(.info, "Bridge received ready event")
            delegate?.bridgeDidBecomeReady(self)
        case .native:
            log(.info, "Bridge received native event")
            guard let json = message.body as? [String: Any], let request = FlowBridgeRequest(json: json) else {
                log(.error, "Invalid JSON data in flow native event", message.body)
                delegate?.bridgeDidFailAuthentication(self, error: DescopeError.flowFailed.with(message: "Invalid JSON data in flow native event"))
                return
            }
            delegate?.bridgeDidReceiveRequest(self, request: request)
        case .failure:
            log(.error, "Bridge received failure event", message.body)
            delegate?.bridgeDidFailAuthentication(self, error: DescopeError.flowFailed.with(message: "Unexpected authentication failure [\(message.body)]"))
        case .success:
            log(.info, "Bridge received success event")
            guard let json = message.body as? String, case let data = Data(json.utf8) else {
                log(.error, "Invalid JSON data in flow success event", message.body)
                delegate?.bridgeDidFailAuthentication(self, error: DescopeError.flowFailed.with(message: "Invalid JSON data in flow success event"))
                return
            }
            delegate?.bridgeDidFinishAuthentication(self, data: data)
        case nil:
            log(.error, "Bridge received unexpected message", message.name)
        }
    }
}

extension FlowBridge: WKNavigationDelegate {
    func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction) async -> WKNavigationActionPolicy {
        log(.info, "Webview will load url", navigationAction.navigationType == .other ? nil : "type=\(navigationAction.navigationType.rawValue)", navigationAction.request.url?.absoluteString)
        return .allow
    }

    func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation) {
        log(.info, "Webview started loading webpage")
        delegate?.bridgeDidStartLoading(self)
    }

    func webView(_ webView: WKWebView, didReceiveServerRedirectForProvisionalNavigation navigation: WKNavigation) {
        log(.info, "Webview received server redirect", webView.url)
    }

    func webView(_ webView: WKWebView, decidePolicyFor navigationResponse: WKNavigationResponse) async -> WKNavigationResponsePolicy {
        log(.info, "Webview will receive response")
        return .allow
    }

    func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation, withError error: Error) {
        log(.error, "Webview failed loading url", error)
        delegate?.bridgeDidFailLoading(self, error: DescopeError.networkError.with(cause: error))
    }

    func webView(_ webView: WKWebView, didCommit navigation: WKNavigation) {
        log(.info, "Webview received response")
    }

    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation) {
        log(.info, "Webview finished loading webpage")
        delegate?.bridgeDidFinishLoading(self)
        webView.evaluateJavaScript("waitWebComponent()")
    }

    func webView(_ webView: WKWebView, didFail navigation: WKNavigation, withError error: Error) {
        log(.error, "Webview failed loading webpage", error)
        delegate?.bridgeDidFailLoading(self, error: DescopeError.networkError.with(cause: error))
    }
}

extension FlowBridge: WKUIDelegate {
    func webView(_ webView: WKWebView, createWebViewWith configuration: WKWebViewConfiguration, for navigationAction: WKNavigationAction, windowFeatures: WKWindowFeatures) -> WKWebView? {
        // TODO
        log(.info, "Webview createWebViewWith", navigationAction.request, navigationAction, windowFeatures)
        return nil
    }
}

private enum FlowBridgeMessage: String, CaseIterable {
    case log, warn, error, ready, native, failure, success
}

private extension FlowBridgeRequest {
    init?(json: [String: Any]) {
        switch json["type"] as? String {
        case "oauthNative":
            guard let start = json["response"] as? [String: Any] else { return nil }
            guard let clientId = start["clientId"] as? String, let stateId = start["stateId"] as? String, let nonce = start["nonce"] as? String, let implicit = start["implicit"] as? Bool else { return nil }
            self = .oauthNative(clientId: clientId, stateId: stateId, nonce: nonce, implicit: implicit)
        case "oauthWeb":
            guard let url = json["url"] as? String else { return nil }
            var defaultProvider: String?
            if let value = json["defaultProvider"] as? String, !value.isEmpty {
                defaultProvider = value
            }
            self = .oauthWeb(url: url, defaultProvider: defaultProvider)
        default:
            return nil
        }
    }
}

private extension FlowBridgeResponse {
    var dictionaryValue: [String: Any] {
        var dict: [String: Any] = [:]
        switch self {
        case let .oauthNative(stateId, authorizationCode, identityToken, user):
            dict["stateId"] = stateId
            if let authorizationCode {
                dict["code"] = authorizationCode
            }
            if let identityToken {
                dict["idToken"] = identityToken
            }
            if let user {
                dict["user"] = user
            }
        }
        return dict
    }

    var stringValue: String {
        guard let json = try? JSONSerialization.data(withJSONObject: dictionaryValue), let str = String(bytes: json, encoding: .utf8) else { return "{}" }
        return str
            .replacingOccurrences(of: #"\"#, with: #"\\"#)
            .replacingOccurrences(of: #"$"#, with: #"\$"#)
            .replacingOccurrences(of: #"`"#, with: #"\`"#)
    }
}

private let setupScript = """
 
/* Javascript code that's executed once the page finished loading */

// Redirect console logs to bridge
window.console.log = (s) => { window.webkit.messageHandlers.log.postMessage(s) }
window.console.warn = (s) => { window.webkit.messageHandlers.warn.postMessage(s) }
window.console.error = (s) => { window.webkit.messageHandlers.error.postMessage(s) }

// Finds the Descope web-component in the webpage
function findWebComponent() {
    return document.getElementsByTagName('descope-wc')[0]
}

// Called by bridge when the WebView finished loading
function waitWebComponent() {
    document.body.style.background = 'transparent'

    const styles = `
        :root {
          color-scheme: light dark;
        }
    `

    const stylesheet = document.createElement("style")
    stylesheet.textContent = styles
    document.head.appendChild(stylesheet)

    let interval
    interval = setInterval(() => {
        let component = findWebComponent()
        if (component) {
            clearInterval(interval)
            prepareWebComponent(component)
        }
    }, 20)
}

// Attaches event listeners once the Descope web-component is ready
function prepareWebComponent(component) {
    const parent = component.parentElement?.parentElement
    if (parent) {
        parent.style.boxShadow = 'unset'
    }

    component.addEventListener('ready', () => {
        window.webkit.messageHandlers.ready.postMessage('')
    })

    component.addEventListener('native', (event) => {
        window.webkit.messageHandlers.native.postMessage(event.detail)
    })

    component.addEventListener('error', (event) => {
        window.webkit.messageHandlers.failure.postMessage(event.detail)
    })

    component.addEventListener('success', (event) => {
        window.webkit.messageHandlers.success.postMessage(JSON.stringify(event.detail))
    })
}

"""

#endif
