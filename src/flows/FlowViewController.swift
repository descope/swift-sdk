
#if os(iOS)

import UIKit
import WebKit

@MainActor
public protocol DescopeFlowViewControllerViewDelegate: AnyObject {
    func flowViewControllerDidUpdateState(_ controller: DescopeFlowViewController, to state: DescopeFlowState, from previous: DescopeFlowState)
    func flowViewControllerDidBecomeReady(_ controller: DescopeFlowViewController)
    func flowViewControllerShouldShowURL(_ controller: DescopeFlowViewController, url: URL, external: Bool) -> Bool
    func flowViewControllerDidCancel(_ controller: DescopeFlowViewController)
    func flowViewControllerDidFail(_ controller: DescopeFlowViewController, error: DescopeError)
    func flowViewControllerDidFinish(_ controller: DescopeFlowViewController, response: AuthenticationResponse)
}

public class DescopeFlowViewController: UIViewController {

    private lazy var flowView: DescopeFlowView = createFlowView()

    public weak var delegate: DescopeFlowViewControllerViewDelegate?

    public var state: DescopeFlowState {
        return flowView.state
    }

    public convenience init(preloading flow: DescopeFlow) {
        self.init()
        start(flow: flow)
    }

    public override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = .secondarySystemBackground

        activityView.color = .label
        navigationItem.rightBarButtonItem = UIBarButtonItem(customView: activityView)

        flowView.frame = view.bounds
        flowView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        view.addSubview(flowView)
    }

    private lazy var activityView = UIActivityIndicatorView()

    public func start(flow: DescopeFlow) {
        flowView.delegate = self
        flowView.start(flow: flow)
    }

    public override func didMove(toParent parent: UIViewController?) {
        super.didMove(toParent: parent)
        if navigationController?.topViewController == self {
            navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: .cancel, target: self, action: #selector(handleCancel))
        } else {
            navigationItem.leftBarButtonItem = nil
        }
    }

    // Internal

    @objc private func handleCancel() {
        delegate?.flowViewControllerDidCancel(self)
    }

    private func createFlowView() -> DescopeFlowView {
        return DescopeCustomFlowView(frame: isViewLoaded ? view.bounds : UIScreen.main.bounds)
    }
}

extension DescopeFlowViewController: DescopeFlowViewDelegate {
    public func flowViewDidUpdateState(_ flowView: DescopeFlowView, to state: DescopeFlowState, from previous: DescopeFlowState) {
        if state == .started {
            activityView.startAnimating()
        } else {
            activityView.stopAnimating()
        }
        delegate?.flowViewControllerDidUpdateState(self, to: state, from: previous)
    }
    
    public func flowViewDidBecomeReady(_ flowView: DescopeFlowView) {
        delegate?.flowViewControllerDidBecomeReady(self)
    }

    public func flowViewDidInterceptNavigation(_ flowView: DescopeFlowView, url: URL, external: Bool) {
        let open = delegate?.flowViewControllerShouldShowURL(self, url: url, external: external) ?? true
        if open {
            UIApplication.shared.open(url)
        }
    }

    public func flowViewDidFailAuthentication(_ flowView: DescopeFlowView, error: DescopeError) {
        delegate?.flowViewControllerDidFail(self, error: error)
    }
    
    public func flowViewDidFinishAuthentication(_ flowView: DescopeFlowView, response: AuthenticationResponse) {
        delegate?.flowViewControllerDidFinish(self, response: response)
    }
}

private class DescopeCustomFlowView: DescopeFlowView {
    override class var webViewClass: WKWebView.Type {
        return DescopeCustomWebView.self
    }
}

private class DescopeCustomWebView: WKWebView {
    override var inputAccessoryView: UIView? {
        return nil
    }
}

#endif
