
#if os(iOS)

import UIKit
import WebKit

/// A set of delegate methods for events about the flow running in a ``DescopeFlowViewController``.
@MainActor
public protocol DescopeFlowViewControllerDelegate: AnyObject {
    func flowViewControllerDidUpdateState(_ controller: DescopeFlowViewController, to state: DescopeFlowState, from previous: DescopeFlowState)
    func flowViewControllerDidBecomeReady(_ controller: DescopeFlowViewController)
    func flowViewControllerShouldShowURL(_ controller: DescopeFlowViewController, url: URL, external: Bool) -> Bool
    func flowViewControllerDidCancel(_ controller: DescopeFlowViewController)
    func flowViewControllerDidFail(_ controller: DescopeFlowViewController, error: DescopeError)
    func flowViewControllerDidFinish(_ controller: DescopeFlowViewController, response: AuthenticationResponse)
}

/// A utility class for presenting a Descope Flow.
///
/// You can use an instance of ``DescopeFlowViewController`` as a standalone view controller or
/// in a navigation controller stack. In the latter case, if the flow view controller is at the
/// top of the stack, it shows a `Cancel` button where the back arrow usually is.
///
/// ```swift
/// fun showLoginScreen() {
///     let url = URL(string: "https://example.com/myflow")!
///     let flow = DescopeFlow(url: url)
///
///     let flowViewController = DescopeFlowViewController()
///     flowViewController.delegate = self
///     flowViewController.start(flow: flow)
///
///     navigationController?.pushViewController(flowViewController, animated: true)
/// }
///
/// func flowViewControllerDidFinish(_ controller: DescopeFlowViewController, response: AuthenticationResponse) {
///     let session = DescopeSession(from: response)
///     Descope.sessionManager.manageSession(session)
///     showMainScreen()
/// }
/// ```
public class DescopeFlowViewController: UIViewController {

    private lazy var flowView: DescopeFlowView = createFlowView()

    public weak var delegate: DescopeFlowViewControllerDelegate?

    public var state: DescopeFlowState {
        return flowView.state
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

    public override func willMove(toParent parent: UIViewController?) {
        super.willMove(toParent: parent)
        if let navigationController, navigationController.topViewController === self, navigationController.viewControllers.count == 1 {
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
        return DescopeFlowView(frame: isViewLoaded ? view.bounds : UIScreen.main.bounds)
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

#endif
