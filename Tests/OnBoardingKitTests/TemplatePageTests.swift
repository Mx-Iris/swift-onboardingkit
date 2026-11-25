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

    private static func rows(of bulletList: OBTemplatePartBulletList) throws -> [OBTemplatePartBulletListItem] {
        try #require(bulletList.stack).arrangedSubviews.compactMap { $0 as? OBTemplatePartBulletListItem }
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

    @Test("Rows of a page that leaves the spacing alone get the framework's own metrics: 40-point icons")
    func defaultSpacingKeepsFrameworkMetrics() throws {
        let bulletList = try #require(Self.assemble(Self.makePage()).templateView?.bulletList)
        let rows = try Self.rows(of: bulletList)

        #expect(bulletList.bulletListSpacing == .large)
        #expect(rows.count == 2)
        for row in rows {
            #expect(row.iconWidth == 40)
            #expect(row.iconHeight == 40)
            #expect(row.iconTextSpacing == 12)
        }
    }

    @Test("A page's spacing reaches its rows")
    func pageSpacingReachesRows() throws {
        var page = Self.makePage()
        page.featureSpacing = .compact
        let bulletList = try #require(Self.assemble(page).templateView?.bulletList)
        let rows = try Self.rows(of: bulletList)

        #expect(bulletList.bulletListSpacing == .compact)
        #expect(rows.count == 2)
        for row in rows {
            #expect(row.iconWidth == 24)
            #expect(row.iconTextSpacing == 16)
        }
    }

    @Test("Once laid out, each row's image is as wide as its icon")
    func rowImagesAreLaidOutAtIconSize() throws {
        let controller = Self.assemble(Self.makePage())
        let window = NSWindow(contentViewController: controller)
        window.isReleasedWhenClosed = false
        defer { window.close() }
        let templateView = try #require(controller.templateView)

        window.layoutIfNeeded()
        templateView.viewWillDraw()
        window.layoutIfNeeded()

        let rows = try Self.rows(of: try #require(templateView.bulletList))
        #expect(rows.count == 2)
        for row in rows {
            let imageFrame = try #require(row.imageView).frame
            #expect(imageFrame.width == 40)
            // The framework stretches the image to the text's height on 27.2 (58 or 59 points for these rows) and
            // draws the symbol at its own size in the middle; only a zero height would hide it.
            #expect(imageFrame.height >= 40)
        }
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
