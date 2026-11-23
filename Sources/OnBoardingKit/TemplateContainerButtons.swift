import AppKit
import COnBoardingKit
import ObjectiveC

extension OBTemplateContainerViewController {
    /// The role of a button in the tray under the template.
    ///
    /// From macOS 26 on the tray holds a primary, a secondary and a cancel button. Before macOS 26 it holds a first
    /// button, a second button and a link-styled button; the framework maps first to primary, second to cancel and the
    /// link button to secondary, and so does this type.
    public enum ButtonRole: Sendable {
        /// The default button: "Continue", "Get Started". It answers Return.
        case primary
        /// An alternative such as "Learn More". Before macOS 26 it is drawn as a link.
        case secondary
        /// The button that dismisses without acting: "Not Now", "Cancel". It answers Escape.
        case cancel
    }

    /// A button of the tray: its title, and what clicking it does.
    public struct Button {
        public var title: String
        /// Called on the main actor with the controller the button belongs to, so the closure does not need to capture
        /// the controller to dismiss it.
        public var action: @MainActor (OBTemplateContainerViewController) -> Void

        public init(_ title: String, action: @escaping @MainActor (OBTemplateContainerViewController) -> Void) {
            self.title = title
            self.action = action
        }
    }

    /// A controller showing `templateView` above a tray with a primary button and, optionally, a secondary and a
    /// cancel button, each calling its action when clicked.
    ///
    /// ```swift
    /// let controller = OBTemplateContainerViewController(
    ///     templateView: templateView,
    ///     primaryButton: .init("Continue") { controller in controller.dismiss(nil) }
    /// )
    /// window.contentViewController?.presentAsSheet(controller)
    /// ```
    public convenience init(
        templateView: OBTemplateView,
        primaryButton: Button,
        secondaryButton: Button? = nil,
        cancelButton: Button? = nil
    ) {
        // The first/second/link initializer exists on every supported macOS and maps onto primary/cancel/secondary
        // from macOS 26 on.
        self.init(
            templateView: templateView,
            firstButtonTitle: primaryButton.title,
            secondButtonTitle: cancelButton?.title,
            linkButtonTitle: secondaryButton?.title
        )
        setAction(for: .primary, primaryButton.action)
        if let secondaryButton {
            setAction(for: .secondary, secondaryButton.action)
        }
        if let cancelButton {
            setAction(for: .cancel, cancelButton.action)
        }
    }

    /// The tray's button for a role, whichever tray the running macOS builds. `nil` when the tray has no such button.
    public func button(for role: ButtonRole) -> NSButton? {
        if #available(macOS 26.0, *) {
            switch role {
            case .primary: primaryButton
            case .secondary: secondaryButton
            case .cancel: cancelButton
            }
        } else {
            switch role {
            case .primary: firstButton
            case .secondary: linkButton
            case .cancel: secondButton
            }
        }
    }

    /// Makes clicking the role's button call `action`, replacing the button's target and action. The primary button
    /// gets Return as its key equivalent and the cancel button Escape, which the framework does not set.
    ///
    /// Does nothing when the tray has no button for the role.
    public func setAction(for role: ButtonRole, _ action: @escaping @MainActor (OBTemplateContainerViewController) -> Void) {
        guard let button = button(for: role) else { return }
        let actionTarget = ButtonActionTarget(controller: self, action: action)
        // An NSControl keeps its target weakly; the button owns the target for as long as it uses it.
        objc_setAssociatedObject(button, &ButtonActionTarget.associationKey, actionTarget, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        button.target = actionTarget
        button.action = #selector(ButtonActionTarget.performAction(_:))
        switch role {
        case .primary:
            button.keyEquivalent = "\r"
        case .cancel:
            button.keyEquivalent = "\u{1b}"
        case .secondary:
            break
        }
    }
}

/// The target a tray button sends its action to.
@MainActor
private final class ButtonActionTarget: NSObject {
    static var associationKey: UInt8 = 0

    private weak var controller: OBTemplateContainerViewController?
    private let action: @MainActor (OBTemplateContainerViewController) -> Void

    init(controller: OBTemplateContainerViewController, action: @escaping @MainActor (OBTemplateContainerViewController) -> Void) {
        self.controller = controller
        self.action = action
    }

    @objc func performAction(_ sender: Any?) {
        guard let controller else { return }
        action(controller)
    }
}
