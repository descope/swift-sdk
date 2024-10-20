
#if os(iOS)

import UIKit
import WebKit

@MainActor
public protocol DescopeFlowViewControllerViewDelegate: AnyObject {
    func flowViewControllerDidUpdateState(_ controller: DescopeFlowViewController, to state: DescopeFlowState, from previous: DescopeFlowState)
    func flowViewControllerDidBecomeReady(_ controller: DescopeFlowViewController)
    func flowViewControllerDidCancel(_ controller: DescopeFlowViewController)
    func flowViewControllerDidFail(_ controller: DescopeFlowViewController, error: DescopeError)
    func flowViewControllerDidFinish(_ controller: DescopeFlowViewController, response: AuthenticationResponse)
}

public class DescopeFlowViewController: UIViewController {

    public private(set) lazy var flowView: DescopeFlowView = createFlowView()

    public weak var delegate: DescopeFlowViewControllerViewDelegate?

    public var state: DescopeFlowState {
        return flowView.state
    }

    public override func viewDidLoad() {
        super.viewDidLoad()

        activityView.color = .placeholderText

        navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: .cancel, target: self, action: #selector(handleCancel))
        navigationItem.rightBarButtonItem = UIBarButtonItem(customView: activityView)

        view.backgroundColor = .secondarySystemBackground

        flowView.frame = view.bounds
        flowView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        view.addSubview(flowView)
    }

    private lazy var activityView = UIActivityIndicatorView()

    public func start(runner: DescopeFlowRunner) {
        flowView.delegate = self
        flowView.start(runner: runner)
    }

    /// Internal

    @objc
    private func handleCancel() {
        delegate?.flowViewControllerDidCancel(self)
    }

    private func createFlowView() -> DescopeFlowView {
        return DescopeCustomFlowView(frame: isViewLoaded ? view.bounds : UIScreen.main.bounds)
    }
}

extension DescopeFlowViewController: DescopeFlowViewDelegate {
    public func flowViewDidUpdateState(_ flowView: DescopeFlowView, to state: DescopeFlowState, from previous: DescopeFlowState) {
        switch state {
        case .started:
            activityView.startAnimating()
        default:
            activityView.stopAnimating()
        }
        delegate?.flowViewControllerDidUpdateState(self, to: state, from: previous)
    }
    
    public func flowViewDidStartLoading(_ flowView: DescopeFlowView) {
        // nothing
    }
    
    public func flowViewDidFailLoading(_ flowView: DescopeFlowView, error: DescopeError) {
        delegate?.flowViewControllerDidFail(self, error: error)
    }
    
    public func flowViewDidFinishLoading(_ flowView: DescopeFlowView) {
        // nothing
    }
    
    public func flowViewDidBecomeReady(_ flowView: DescopeFlowView) {
        delegate?.flowViewControllerDidBecomeReady(self)
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
