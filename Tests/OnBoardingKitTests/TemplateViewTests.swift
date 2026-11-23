import AppKit
import Testing
import OnBoardingKit

@MainActor
@Suite("Template view")
struct TemplateViewTests {
    @Test("The convenience initializer sets the title, body text, symbol and layout style")
    func convenienceInitializer() {
        let templateView = OBTemplateView(title: "Welcome", bodyText: "Start here.", systemImage: "sparkles", layoutStyle: .headline)
        #expect(templateView.title == "Welcome")
        #expect(templateView.bodyText == "Start here.")
        #expect(templateView.topImageSymbolName == "sparkles")
        #expect(templateView.layoutStyle == .headline)
        #expect(templateView.templateType == .standard)
    }

    @Test("The feature builder makes a bullet list the content area")
    func featureBuilderSetsContentArea() throws {
        let templateView = OBTemplateView(title: "What's New", systemImage: "star") {
            OBTemplatePartBulletList.Item("Faster", description: "Opens in half the time.", systemImage: "bolt")
            OBTemplatePartBulletList.Item("Shared", description: "Edit with others.", systemImage: "person.2")
        }
        let bulletList = try #require(templateView.bulletList)
        #expect(templateView.contentArea === bulletList)
        #expect(bulletList.stack?.arrangedSubviews.count == 2)
    }

    @Test("A What's New page assembles into a container whose view hierarchy holds the bullet list")
    func assemblesIntoContainer() throws {
        let templateView = OBTemplateView(title: "What's New", systemImage: "star") {
            OBTemplatePartBulletList.Item("Faster", systemImage: "bolt")
        }
        let controller = OBTemplateContainerViewController(
            templateView: templateView,
            primaryButton: .init("Continue") { _ in }
        )
        _ = controller.view
        // The template builds its subviews when it is about to draw for the first time; a window that is never shown
        // never draws, so stand in for that first draw.
        #expect(templateView.subviews.isEmpty)
        templateView.viewWillDraw()
        let bulletList = try #require(templateView.bulletList)
        #expect(bulletList.isDescendant(of: controller.view))
    }

    @Test("Privacy identifiers name the system's privacy bundles")
    func privacyIdentifiersNameBundles() {
        #expect(OBPrivacyIdentifier.appStore.rawValue.hasPrefix("com.apple.onboarding."))
        #expect(OBBundle(identifier: .appStore) != nil)
    }
}
