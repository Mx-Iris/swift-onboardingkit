import AppKit
import Testing
import OnBoardingKit

/// The container's size. Windows and sheets are made but never put on screen.
@MainActor
@Suite("Template container sizing")
struct TemplateContainerSizingTests {
    private static let sheetWidth: CGFloat = 482
    private static let shortestSheetHeight: CGFloat = 546
    private static let tallestSheetHeight: CGFloat = 600

    private static func makeController() -> OBTemplateContainerViewController {
        let templateView = OBTemplateView(title: "What's New", bodyText: "Body text.", systemImage: "sparkles") {
            OBTemplatePartBulletList.Item("Offline Maps", description: "Use a region without a connection.", systemImage: "arrow.down.circle")
        }
        return OBTemplateContainerViewController(templateView: templateView, primaryButton: .init("Continue") { _ in })
    }

    @Test("With no parent window a sheet is as large as the framework's own sheet without one")
    func sheetSizeWithoutParentWindow() {
        let expectedSize = NSSize(width: Self.sheetWidth, height: Self.shortestSheetHeight)

        #expect(OBTemplateContainerViewController.sheetSize() == expectedSize)
        #expect(OBTemplateContainerViewController.sheetSize(forParentWindowSize: .zero) == expectedSize)
    }

    @Test("On a short window a sheet keeps the shortest height")
    func sheetSizeOnShortParentWindow() {
        let size = OBTemplateContainerViewController.sheetSize(forParentWindowSize: NSSize(width: 800, height: 500))

        #expect(size == NSSize(width: Self.sheetWidth, height: Self.shortestSheetHeight))
    }

    @Test("On a tall window a sheet stops at the tallest height")
    func sheetSizeOnTallParentWindow() {
        let size = OBTemplateContainerViewController.sheetSize(forParentWindowSize: NSSize(width: 1200, height: 900))

        #expect(size == NSSize(width: Self.sheetWidth, height: Self.tallestSheetHeight))
    }

    @Test("In between, a sheet is 88 % as tall as its window")
    func sheetSizeOnMediumParentWindow() {
        let size = OBTemplateContainerViewController.sheetSize(forParentWindowSize: NSSize(width: 1000, height: 650))
        let expectedHeight: CGFloat = 572
        let heightError = abs(size.height - expectedHeight)

        #expect(size.width == Self.sheetWidth)
        #expect(heightError < 0.001)
    }

    @Test("The convenience initializer lays the template out with constraints and asks for the sheet size")
    func convenienceInitializerSetsLayout() throws {
        let controller = Self.makeController()

        #expect(try #require(controller.templateView).translatesAutoresizingMaskIntoConstraints == false)
        #expect(controller.preferredContentSize == OBTemplateContainerViewController.sheetSize())
    }

    /// The template's initializers give it a zero frame; translating its autoresizing mask, it holds itself, the
    /// container and the window at 0 x 0.
    @Test("A window made from the controller is the sheet size, and the template fills it")
    func windowMadeFromControllerHasSheetSize() throws {
        let controller = Self.makeController()
        let expectedSize = OBTemplateContainerViewController.sheetSize()

        let window = NSWindow(contentViewController: controller)
        window.isReleasedWhenClosed = false
        defer { window.close() }
        window.layoutIfNeeded()

        #expect(window.contentRect(forFrameRect: window.frame).size == expectedSize)
        #expect(try #require(controller.templateView).frame.size == expectedSize)
        #expect(try #require(controller.buttonTray).frame.width == expectedSize.width)
    }

    @Test("A sheet sized for its window is that size, and the template fills it")
    func sheetSizedForParentWindow() throws {
        let parentWindowSize = NSSize(width: 1000, height: 650)
        let parentWindow = NSWindow(
            contentRect: NSRect(origin: .zero, size: parentWindowSize),
            styleMask: [.titled],
            backing: .buffered,
            defer: true
        )
        parentWindow.isReleasedWhenClosed = false
        defer { parentWindow.close() }
        let parentViewController = NSViewController()
        parentViewController.view = NSView(frame: NSRect(origin: .zero, size: parentWindowSize))
        parentWindow.contentViewController = parentViewController
        let controller = Self.makeController()
        let expectedSize = OBTemplateContainerViewController.sheetSize(forParentWindowSize: parentWindow.frame.size)
        controller.preferredContentSize = expectedSize

        parentViewController.presentAsSheet(controller)
        defer { parentViewController.dismiss(controller) }
        let sheetWindow = try #require(controller.view.window)
        sheetWindow.layoutIfNeeded()

        #expect(sheetWindow.contentRect(forFrameRect: sheetWindow.frame).size == expectedSize)
        #expect(try #require(controller.templateView).frame.size == expectedSize)
    }
}
