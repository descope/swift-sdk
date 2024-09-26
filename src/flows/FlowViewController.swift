
import WebKit

open class DescopeFlowViewController: UIViewController {

    public lazy var flowView = createFlowView()

    open override func viewDidLoad() {
        super.viewDidLoad()

        flowView.frame = view.bounds
        flowView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        view.addSubview(flowView)
    }

    /// Internal

    private func createFlowView() -> DescopeFlowView {
        return DescopeFlowView(frame: isViewLoaded ? view.bounds : UIScreen.main.bounds)
    }
}
