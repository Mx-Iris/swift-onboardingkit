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
    /// The template is laid out with constraints (its `translatesAutoresizingMaskIntoConstraints` is turned off), and
    /// the controller's `preferredContentSize` is the size the framework gives its own sheets with no parent window,
    /// ``sheetSize(forParentWindowSize:)``. A window made from the controller, or a sheet it is presented as, opens at
    /// that size. For a sheet whose height follows its window's, set `preferredContentSize` to
    /// `sheetSize(forParentWindowSize: window.frame.size)` before presenting it.
    ///
    /// A template still of the type its initializers give it, `.standard`, or of `.unspecified`, becomes
    /// `.centered`, and so does its bullet list: the standard type's 175-point side margins are meant for a whole
    /// window, and leave the text of a 482-point sheet a column about 130 points wide. A template given another type
    /// keeps it. The template reads its type when it first draws, so a type set after this initializer still counts.
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
        // The template's initializers give it a zero frame and leave it translating its autoresizing mask, while the
        // container pins its edges with constraints: the template would hold itself, the container and any window
        // made from it at 0 x 0 with required constraints.
        templateView.translatesAutoresizingMaskIntoConstraints = false
        // The centered type has 68-point side margins and keeps its bullet list's rows 344 points wide, the width a
        // 482-point sheet leaves. The template does not pass its type on to its bullet list.
        if templateView.templateType == .standard || templateView.templateType == .unspecified {
            templateView.templateType = .centered
            templateView.bulletList?.templateType = .centered
        }
        // The first/second/link initializer exists on every supported macOS and maps onto primary/cancel/secondary
        // from macOS 26 on.
        self.init(
            templateView: templateView,
            firstButtonTitle: primaryButton.title,
            secondButtonTitle: cancelButton?.title,
            linkButtonTitle: secondaryButton?.title
        )
        // The container's view starts at zero and nothing in it has a width; the template builds its subviews only
        // when it first draws.
        preferredContentSize = Self.sheetSize()
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
