
#if os(iOS)

import UIKit
import WebKit

@MainActor
open class DescopeFlowHook {
    public let event: Event

    public init(event: Event) {
        self.event = event
    }

    open func execute(coordinator: DescopeFlowCoordinator) {
    }

    public enum Event {
        case started

        case loaded

        case ready

        case layout
    }
}

/// Default hooks
extension DescopeFlowHook {
    public static let disableTouchCallouts = AddStyles(selector: "*", rule: "-webkit-touch-callout: none")

    public static let enableTouchCallouts = AddStyles(selector: "*", rule: "-webkit-touch-callout: default")

    public static let disableTextSelection = AddStyles(selector: "*", rule: "-webkit-user-select: none")

    public static let enableTextSelection = AddStyles(selector: "*", rule: "-webkit-user-select: auto")

    /// Disables two finger and double tap zooming.
    ///
    /// - Note: This hook is always run automatically when the flow webpage is loaded,
    ///     so there's no need to add it manually.
    public static let disableZoom = SetViewport("width=device-width, initial-scale=1, maximum-scale=1, user-scalable=no")

    /// Enables two finger and double tap zooming.
    ///
    /// Add this hook if you explicitly want to allow zoom gestures to work in the flow webpage.
    public static let enableZoom = SetViewport("width=device-width, initial-scale=1")
}

/// Example
extension DescopeFlowHook {

    public static let transparentBackground = AddStyles(selector: "body", rule: "background-color: transparent")

}


/// Hook building blocks
extension DescopeFlowHook {

    public class RunJavaScript: DescopeFlowHook {
        public let code: String

        public init(event: Event = .loaded, code: String) {
            self.code = code
            super.init(event: event)
        }

        public override func execute(coordinator: DescopeFlowCoordinator) {
            coordinator.runJavaScript(code)
        }
    }

    public class AddStyles: DescopeFlowHook {
        public let css: String

        public init(event: Event = .loaded, css: String) {
            self.css = css
            super.init(event: event)
        }

        public convenience init(event: Event = .loaded, selector: String, rules: [String]) {
            self.init(event: event, css: """
                \(selector) {
                    \(rules.map { $0 + ";" }.joined(separator: "\n"))
                }
            """)
        }

        public convenience init(event: Event = .loaded, selector: String, rule: String) {
            self.init(event: event, selector: selector, rules: [rule])
        }

        public override func execute(coordinator: DescopeFlowCoordinator) {
            coordinator.addStyles(css)
        }
    }

    public class SetupScrollView: DescopeFlowHook {
        public let closure: (UIScrollView) -> Void

        public init(event: Event = .started, closure: @escaping (UIScrollView) -> Void) {
            self.closure = closure
            super.init(event: event)
        }

        public override func execute(coordinator: DescopeFlowCoordinator) {
            guard let scrollView = coordinator.webView?.scrollView else { return }
            closure(scrollView)
        }
    }

    /// Adds or updates the viewport meta tag in the flow webpage.
    public class SetViewport: RunJavaScript {
        public init(_ value: String) {
            super.init(code: """
                const content = \(value.javaScriptLiteralString())
                let viewport = document.head.querySelector('meta[name=viewport]')
                if (viewport) {
                    viewport.content = content 
                } else {
                    viewport = document.createElement('meta')
                    viewport.name = 'viewport'
                    viewport.content = content
                    document.head.appendChild(viewport)
                }
            """)
        }
    }
}

/// Advanced examples
extension DescopeFlowHook {
    open class EvaluateJavaScript: DescopeFlowHook {
        public let code: String

        public init(event: Event = .loaded, code: String) {
            self.code = code
            super.init(event: event)
        }

        public override func execute(coordinator: DescopeFlowCoordinator) {
            Task {
                let result = await coordinator.evaluateJavaScript(code)
                didEvaluateJavaScript(coordinator: coordinator, result: result)
            }
        }

        open func didEvaluateJavaScript(coordinator: DescopeFlowCoordinator, result: Any?) {
        }
    }

    public class SynchronizeViewHeight: EvaluateJavaScript {
        public weak var view: UIView?

        public init(selector: String) {
            super.init(event: .ready, code: """
                const element = document.querySelector(\(selector.javaScriptLiteralString()))
                if (element) {
                    const rect = element.getBoundingClientRect()
                    return rect.height
                } else {
                    console.error(`Element not found: ${selector}`)
                }
            """)
        }

        public override func didEvaluateJavaScript(coordinator: DescopeFlowCoordinator, result: Any?) {
            guard let height = result as? CGFloat else { return }
            view?.bounds.size.height = height
        }
    }

    public class SynchronizeContentSize: DescopeFlowHook {
        public let selectors: [String]

        public init(selectors: [String]) {
            self.selectors = selectors
            super.init(event: .ready)
        }

        open func contentSize(scrollView: UIScrollView) -> CGSize {
            let size = scrollView.bounds.size
            let insets = scrollView.adjustedContentInset

            let width = size.width - insets.left - insets.right
            let height = size.height - insets.top - insets.bottom
            
            return CGSize(width: width, height: height)
        }

        public override func execute(coordinator: DescopeFlowCoordinator) {
            guard let scrollView = coordinator.webView?.scrollView else { return }
            let size = contentSize(scrollView: scrollView)
            coordinator.runJavaScript("""
                const selectors = [ \(selectors.map { $0.javaScriptLiteralString() }.joined(separator: ", ")) ]
                for (selector of selectors) {
                    const element = document.querySelector(selector)
                    if (element) {
                        element.style.width = '\(size.width)px'
                        element.style.height = '\(size.height)px'
                    } else {
                        console.error(`Element not found: ${selector}`)
                    }
                }
            """)
        }
    }
}

#endif
