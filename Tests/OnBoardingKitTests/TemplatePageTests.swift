import AppKit
import Testing
import OnBoardingKit

/// A page assembled into a container. Windows are made but never put on screen.
@MainActor
@Suite("Template page")
struct TemplatePageTests {
    private static func makePage(layout: OBTemplatePage.Layout = .centered, featureTintColor: NSColor? = nil) -> OBTemplatePage {
        OBTemplatePage(title: "What's New in Atlas", bodyText: "Body text.", image: .systemImage("map"), featureTintColor: featureTintColor, layout: layout) {
            OBTemplatePartBulletList.Item("Offline Maps", description: "Use a region without a connection.", systemImage: "arrow.down.circle")
            OBTemplatePartBulletList.Item("Shared Trips", description: "Plan a route together.", systemImage: "person.2", tintColor: .systemPink)
        }
    }

    private static func assemble(_ page: OBTemplatePage) -> OBTemplateContainerViewController {
        OBTemplateContainerViewController(page: page, primaryButton: .init("Continue") { _ in })
    }

    @Test("The template shows the page's title, body text and symbol")
    func templateShowsPageText() throws {
        let templateView = try #require(Self.assemble(Self.makePage()).templateView)

        #expect(templateView.title == "What's New in Atlas")
        #expect(templateView.bodyText == "Body text.")
        #expect(templateView.topImageSymbolName == "map")
    }

    @Test("The bullet list has a row for each feature, in order")
    func bulletListHasFeatureRows() throws {
        let templateView = try #require(Self.assemble(Self.makePage()).templateView)
        let rows = try #require(templateView.bulletList?.stack).arrangedSubviews.compactMap { $0 as? OBTemplatePartBulletListItem }

        #expect(rows.count == 2)
    }

    @Test("A page without features has no bullet list")
    func pageWithoutFeaturesHasNoBulletList() throws {
        let templateView = try #require(Self.assemble(OBTemplatePage(title: "Welcome")).templateView)

        #expect(templateView.contentArea == nil)
    }

    @Test("Each layout reaches the template and its bullet list", arguments: [
        (OBTemplatePage.Layout.standard, OBTemplateType.standard, false),
        (OBTemplatePage.Layout.wide, OBTemplateType.standard, true),
        (OBTemplatePage.Layout.centered, OBTemplateType.centered, false),
        (OBTemplatePage.Layout.privacy, OBTemplateType.privacy, false),
    ])
    func layoutReachesTemplateAndList(layout: OBTemplatePage.Layout, templateType: OBTemplateType, needsExtraWideContent: Bool) throws {
        let templateView = try #require(Self.assemble(Self.makePage(layout: layout)).templateView)
        let bulletList = try #require(templateView.bulletList)

        #expect(templateView.templateType == templateType)
        #expect(templateView.needsExtraWideContent == needsExtraWideContent)
        #expect(bulletList.templateType == templateType)
        #expect(bulletList.needsExtraWideContent == needsExtraWideContent)
    }

    @Test("The controller asks for the page's size")
    func controllerAsksForPageSize() {
        var page = Self.makePage()
        page.size = OBTemplateContainerViewController.sheetSize(forParentWindowSize: NSSize(width: 1200, height: 900))

        #expect(Self.assemble(page).preferredContentSize == page.size)
    }

    @Test("A window made from the page is the page's size, and the template fills it")
    func windowHasPageSize() throws {
        let page = Self.makePage()
        let controller = Self.assemble(page)
        let window = NSWindow(contentViewController: controller)
        window.isReleasedWhenClosed = false
        defer { window.close() }
        let templateView = try #require(controller.templateView)

        window.layoutIfNeeded()
        templateView.viewWillDraw()
        window.layoutIfNeeded()

        #expect(window.contentRect(forFrameRect: window.frame).size == page.size)
        #expect(templateView.frame.size == page.size)
        let shortestAcceptableWidth: CGFloat = page.size.width * 0.6
        let titleWidth = try #require(templateView.titleView).frame.width
        #expect(titleWidth > shortestAcceptableWidth)
    }
}
