
import WebKit

protocol FlowBridgeDelegate: AnyObject {
    func bridgeDidStartLoading(_ bridge: FlowBridge)
    func bridgeDidFailLoading(_ bridge: FlowBridge, error: DescopeError)
    func bridgeDidFinishLoading(_ bridge: FlowBridge)
    func bridgeDidBecomeReady(_ bridge: FlowBridge)
    func bridgeDidFailAuthentication(_ bridge: FlowBridge, error: DescopeError)
    func bridgeDidFinishAuthentication(_ bridge: FlowBridge, data: Data)
}

class FlowBridge: NSObject, LoggerProvider {
    var logger: DescopeLogger?

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

    public func prepare(configuration: WKWebViewConfiguration) {
        let setup = WKUserScript(source: setupScript, injectionTime: .atDocumentStart, forMainFrameOnly: false)
        configuration.userContentController.addUserScript(setup)

        for name in FlowMessage.allCases {
            configuration.userContentController.add(self, name: name.rawValue)
        }
    }
}

extension FlowBridge: WKScriptMessageHandler {
    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        switch FlowMessage(rawValue: message.name) {
        case .log:
            log(.debug, "Console Log", message.body)
        case .warn:
            log(.debug, "Console Warn", message.body)
        case .error:
            log(.debug, "Console Error", message.body)
        case .ready:
            log(.info, "Bridge received ready event")
            delegate?.bridgeDidBecomeReady(self)
        case .failure:
            log(.error, "Bridge received failure event", message.body)
            delegate?.bridgeDidFailAuthentication(self, error: DescopeError.flowFailed.with(message: "Unexpected authentication failure [\(message.body)]"))
        case .success:
            log(.info, "Bridge received success event")
            guard let json = message.body as? String, case let data = Data(json.utf8) else {
                delegate?.bridgeDidFailAuthentication(self, error: DescopeError.flowFailed.with(message: "Invalid JSON data in flow authentication"))
                return
            }
            delegate?.bridgeDidFinishAuthentication(self, data: data)
        case nil:
            log(.error, "Unexpected message in bridge", message.name)
        }
    }
}

extension FlowBridge: WKNavigationDelegate {
    func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction) async -> WKNavigationActionPolicy {
        log(.info, "Webview decide policy for url", navigationAction.navigationType.rawValue, navigationAction.request.url?.absoluteString)
        if let url = navigationAction.request.url, url.scheme == "descopeauth" {
            // TODO
            return .cancel
        }
        return .allow
    }

    func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
        log(.info, "Webview started loading url", webView.url)
        delegate?.bridgeDidStartLoading(self)
    }

    func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
        log(.error, "Webview failed provisional navigation", error)
        delegate?.bridgeDidFailLoading(self, error: DescopeError.networkError.with(cause: error))
    }

    func webView(_ webView: WKWebView, didCommit navigation: WKNavigation!) {
        log(.info, "Webview commited navigation", webView.url)
    }

    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        log(.info, "Webview finished navigation", webView.url)
        delegate?.bridgeDidFinishLoading(self)
        webView.evaluateJavaScript("waitWebComponent()")
    }

    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        log(.error, "Webview failed navigation", error)
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

private enum FlowMessage: String, CaseIterable {
    case log, warn, error, ready, failure, success
}

private let setupScript = """
 
/* Javascript code that's executed once the script finishes running */

// Redirect console logs to bridge
window.console.log = (s) => { window.webkit.messageHandlers.log.postMessage(s) }
window.console.warn = (s) => { window.webkit.messageHandlers.warn.postMessage(s) }
window.console.error = (s) => { window.webkit.messageHandlers.error.postMessage(s) }

// Called by bridge when the WebView finished loading
function waitWebComponent() {
    document.body.style.background = 'transparent'

    let id
    id = setInterval(() => {
        let wc = document.getElementsByTagName('descope-wc')[0]
        if (wc) {
            clearInterval(id)
            prepareWebComponent(wc)
        }
    }, 20)
}

// Attaches event listeners once the Descope web-component is ready
function prepareWebComponent(wc) {
    const parent = wc?.parentElement?.parentElement
    if (parent) {
        parent.style.boxShadow = 'unset'
    }

    wc.addEventListener('success', (e) => {
        window.webkit.messageHandlers.success.postMessage(JSON.stringify(e.detail))
    })

    wc.addEventListener('error', (e) => {
        window.webkit.messageHandlers.failure.postMessage(e.detail)
    })

    wc.addEventListener('ready', () => {
        window.webkit.messageHandlers.ready.postMessage('')
    })
}

"""
