
#if os(iOS)

import UIKit
import WebKit

@MainActor
public protocol DescopeFlowViewDelegate: AnyObject {
    func flowViewDidUpdateState(_ flowView: DescopeFlowView, to state: DescopeFlowState, from previous: DescopeFlowState)
    func flowViewDidStartLoading(_ flowView: DescopeFlowView)
    func flowViewDidFailLoading(_ flowView: DescopeFlowView, error: DescopeError)
    func flowViewDidFinishLoading(_ flowView: DescopeFlowView)
    func flowViewDidBecomeReady(_ flowView: DescopeFlowView)
    func flowViewDidFailAuthentication(_ flowView: DescopeFlowView, error: DescopeError)
    func flowViewDidFinishAuthentication(_ flowView: DescopeFlowView, response: AuthenticationResponse)
}

open class DescopeFlowView: UIView {

    private let coordinator = DescopeFlowCoordinator()

    private lazy var webView = createWebView()

    public weak var delegate: DescopeFlowViewDelegate?

    public var state: DescopeFlowState {
        return coordinator.state
    }

    /// Setup

    public convenience init() {
        self.init(frame: .zero)
    }

    public override init(frame: CGRect) {
        super.init(frame: frame)
        setupView()
        setupSubviews()
    }

    public required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupView()
        setupSubviews()
    }

    private func setupView() {
        coordinator.delegate = self
    }

    private func setupSubviews() {
        coordinator.webView = webView
        addSubview(webView)
    }

    /// UIView

    open override func layoutSubviews() {
        super.layoutSubviews()
        webView.frame = bounds
    }

    /// Flow

    public func start(runner: DescopeFlowRunner) {
        coordinator.start(runner: runner)
    }

    /// WebView

    private func createWebView() -> WKWebView {
        let configuration = WKWebViewConfiguration()
        _prepareConfiguration(configuration)

        let webViewClass = Self.webViewClass
        let webView = webViewClass.init(frame: bounds, configuration: configuration)
        _prepareWebView(webView)

        return webView
    }

    private func _prepareConfiguration(_ configuration: WKWebViewConfiguration) {
        prepareConfiguration(configuration)
        coordinator.prepare(configuration: configuration)
    }

    private func _prepareWebView(_ webView: WKWebView) {
        webView.isOpaque = false
        webView.backgroundColor = .clear
        webView.scrollView.keyboardDismissMode = .interactiveWithAccessory
        prepareWebView(webView)
    }

    /// Override points

    open class var webViewClass: WKWebView.Type {
        return WKWebView.self
    }

    open func prepareConfiguration(_ configuration: WKWebViewConfiguration) {
    }

    open func prepareWebView(_ webView: WKWebView) {
    }
}

extension DescopeFlowView: DescopeFlowCoordinatorDelegate {
    public func coordinatorDidUpdateState(_ coordinator: DescopeFlowCoordinator, to state: DescopeFlowState, from previous: DescopeFlowState) {
        delegate?.flowViewDidUpdateState(self, to: state, from: previous)
    }
    
    public func coordinatorDidStartLoading(_ coordinator: DescopeFlowCoordinator) {
        delegate?.flowViewDidStartLoading(self)
    }
    
    public func coordinatorDidFailLoading(_ coordinator: DescopeFlowCoordinator, error: DescopeError) {
        delegate?.flowViewDidFailLoading(self, error: error)
    }
    
    public func coordinatorDidFinishLoading(_ coordinator: DescopeFlowCoordinator) {
        delegate?.flowViewDidFinishLoading(self)
    }
    
    public func coordinatorDidBecomeReady(_ coordinator: DescopeFlowCoordinator) {
        delegate?.flowViewDidBecomeReady(self)
    }
    
    public func coordinatorDidFailAuthentication(_ coordinator: DescopeFlowCoordinator, error: DescopeError) {
        delegate?.flowViewDidFailAuthentication(self, error: error)
    }
    
    public func coordinatorDidFinishAuthentication(_ coordinator: DescopeFlowCoordinator, response: AuthenticationResponse) {
        delegate?.flowViewDidFinishAuthentication(self, response: response)
    }
}

#endif
