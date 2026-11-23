import AppKit
import Testing
import OnBoardingKit

/// Stands in for the sheet: ends it on the next turn of the main queue instead of showing anything.
@MainActor
private final class ImmediatelyDismissingPresenter: OBPrivacyPresenter {
    private(set) var presentCallCount = 0

    override func present() {
        presentCallCount += 1
        DispatchQueue.main.async { [self] in
            dismissHandler?()
        }
    }
}

@MainActor
@Suite("Privacy presenter presentation")
struct PrivacyPresenterPresentationTests {
    @Test("presentAsSheet sets the window, presents once and returns after the sheet ends")
    func returnsAfterDismissal() async {
        let presenter = ImmediatelyDismissingPresenter()
        let window = NSWindow(contentRect: NSRect(x: 0, y: 0, width: 400, height: 300), styleMask: [.titled], backing: .buffered, defer: true)
        await presenter.presentAsSheet(on: window)
        #expect(presenter.presentingWindow === window)
        #expect(presenter.presentCallCount == 1)
    }

    @Test("The dismiss handler set before is called and put back")
    func previousHandlerIsRestored() async {
        let presenter = ImmediatelyDismissingPresenter()
        var previousHandlerCallCount = 0
        presenter.dismissHandler = { previousHandlerCallCount += 1 }
        let window = NSWindow(contentRect: NSRect(x: 0, y: 0, width: 400, height: 300), styleMask: [.titled], backing: .buffered, defer: true)

        await presenter.presentAsSheet(on: window)
        #expect(previousHandlerCallCount == 1)

        presenter.dismissHandler?()
        #expect(previousHandlerCallCount == 2)
    }

    @Test("The factories find the system's privacy pages")
    func factoriesFindSystemPages() {
        #expect(OBPrivacyPresenter(splashFor: .appStore) != nil)
        #expect(OBPrivacyPresenter(unifiedAboutFor: [OBPrivacyIdentifier.appStore, .maps]) != nil)
        #expect(OBPrivacyLinkController.link(withBundleIdentifier: .appStore) is OBPrivacyLinkController_macOS)
        #expect(OBPrivacyLinkController.link(withBundleIdentifiers: []) == nil)
    }
}
