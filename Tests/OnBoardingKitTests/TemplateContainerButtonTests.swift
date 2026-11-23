import AppKit
import Testing
import OnBoardingKit

@MainActor
@Suite("Template container buttons")
struct TemplateContainerButtonTests {
    @Test("Each role's button carries its title and calls its action with the controller")
    func buttonsCallTheirActions() throws {
        var calledRoles: [OBTemplateContainerViewController.ButtonRole] = []
        var receivedControllers: [OBTemplateContainerViewController] = []
        let controller = OBTemplateContainerViewController(
            templateView: OBTemplateView(title: "Welcome"),
            primaryButton: .init("Continue") { controller in
                calledRoles.append(.primary)
                receivedControllers.append(controller)
            },
            secondaryButton: .init("Learn More") { controller in
                calledRoles.append(.secondary)
                receivedControllers.append(controller)
            },
            cancelButton: .init("Not Now") { controller in
                calledRoles.append(.cancel)
                receivedControllers.append(controller)
            }
        )

        let primaryButton = try #require(controller.button(for: .primary))
        let secondaryButton = try #require(controller.button(for: .secondary))
        let cancelButton = try #require(controller.button(for: .cancel))
        #expect(primaryButton.title == "Continue")
        #expect(secondaryButton.title == "Learn More")
        #expect(cancelButton.title == "Not Now")

        primaryButton.performClick(nil)
        secondaryButton.performClick(nil)
        cancelButton.performClick(nil)
        #expect(calledRoles == [.primary, .secondary, .cancel])
        #expect(receivedControllers.allSatisfy { $0 === controller })
    }

    @Test("The primary button answers Return and the cancel button Escape")
    func keyEquivalents() throws {
        let controller = OBTemplateContainerViewController(
            templateView: OBTemplateView(title: "Welcome"),
            primaryButton: .init("Continue") { _ in },
            cancelButton: .init("Not Now") { _ in }
        )
        #expect(try #require(controller.button(for: .primary)).keyEquivalent == "\r")
        #expect(try #require(controller.button(for: .cancel)).keyEquivalent == "\u{1b}")
    }

    @Test("A later setAction replaces the earlier one")
    func setActionReplaces() throws {
        var calls: [String] = []
        let controller = OBTemplateContainerViewController(
            templateView: OBTemplateView(title: "Welcome"),
            primaryButton: .init("Continue") { _ in calls.append("original") }
        )
        controller.setAction(for: .primary) { _ in calls.append("replacement") }
        try #require(controller.button(for: .primary)).performClick(nil)
        #expect(calls == ["replacement"])
    }

    @Test("The action does not keep the controller alive")
    func actionDoesNotRetainController() {
        weak var weakController: OBTemplateContainerViewController?
        do {
            let controller = OBTemplateContainerViewController(
                templateView: OBTemplateView(title: "Welcome"),
                primaryButton: .init("Continue") { controller in controller.dismiss(nil) }
            )
            weakController = controller
        }
        #expect(weakController == nil)
    }
}
