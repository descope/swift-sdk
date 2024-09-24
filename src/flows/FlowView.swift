
import WebKit

public protocol DescopeFlowViewDelegate: AnyObject {
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
    }

    open override func awakeFromNib() {
        super.awakeFromNib()
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

    /// Overrides

    open class var webViewClass: WKWebView.Type {
        return WKWebView.self
    }

    private func _prepareConfiguration(_ configuration: WKWebViewConfiguration) {
        prepareConfiguration(configuration)
        coordinator.prepare(configuration: configuration)
    }

    open func prepareConfiguration(_ configuration: WKWebViewConfiguration) {
    }

    private func _prepareWebView(_ webView: WKWebView) {
        webView.isOpaque = false
        webView.backgroundColor = .clear
        webView.scrollView.isScrollEnabled = false
        webView.scrollView.showsVerticalScrollIndicator = false
        webView.scrollView.showsHorizontalScrollIndicator = false
        prepareWebView(webView)
    }

    open func prepareWebView(_ webView: WKWebView) {
    }
}

extension DescopeFlowView: DescopeFlowCoordinatorDelegate {
    public func coordinatorFlowDidStartLoading(_ coordinator: DescopeFlowCoordinator) {
        delegate?.flowViewDidStartLoading(self)
    }
    
    public func coordinatorFlowDidFailLoading(_ coordinator: DescopeFlowCoordinator, error: DescopeError) {
        delegate?.flowViewDidFailLoading(self, error: error)
    }
    
    public func coordinatorFlowDidFinishLoading(_ coordinator: DescopeFlowCoordinator) {
        delegate?.flowViewDidFinishLoading(self)
    }
    
    public func coordinatorFlowDidBecomeReady(_ coordinator: DescopeFlowCoordinator) {
        delegate?.flowViewDidBecomeReady(self)
    }
    
    public func coordinatorFlowDidFailAuthentication(_ coordinator: DescopeFlowCoordinator, error: DescopeError) {
        delegate?.flowViewDidFailAuthentication(self, error: error)
    }
    
    public func coordinatorFlowDidFinishAuthentication(_ coordinator: DescopeFlowCoordinator, response: AuthenticationResponse) {
        delegate?.flowViewDidFinishAuthentication(self, response: response)
    }
}

func foo() {
    let view = DescopeFlowView()
}

class RichEditorWebView: WKWebView {
    var accessoryView: UIView?

    override var inputAccessoryView: UIView? {
        return accessoryView
    }
}

open class DescopeFlowView2: DescopeFlowView {
    override open class var webViewClass: WKWebView.Type {
        return RichEditorWebView.self
    }
}
