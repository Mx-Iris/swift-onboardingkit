import AppKit
import COnBoardingKit

extension OBTemplateContainerViewController {
    /// The size the framework gives the sheets it shows itself: 482 points wide, and 88 % as tall as the window the
    /// sheet hangs off but at least 546 and at most 600 points; 546 points tall with no parent window.
    ///
    /// The framework's own privacy window forces this size from `+[OBStyle sheetSizeForParentWindowSize:]`, which no
    /// app can call: the SDK's text stub does not export `OBStyle`. This repeats it, as on macOS 15.5 and 27.2.
    ///
    /// ```swift
    /// controller.preferredContentSize = OBTemplateContainerViewController.sheetSize(forParentWindowSize: window.frame.size)
    /// window.contentViewController?.presentAsSheet(controller)
    /// ```
    ///
    /// - Parameter parentWindowSize: The frame size of the window the sheet is going to hang off, or `nil` (or a zero
    ///   size, as the framework takes it) for none.
    nonisolated public static func sheetSize(forParentWindowSize parentWindowSize: NSSize? = nil) -> NSSize {
        let width: CGFloat = 482
        let shortestHeight: CGFloat = 546
        let tallestHeight: CGFloat = 600
        let parentHeightFraction: CGFloat = 0.88
        guard let parentWindowSize, parentWindowSize != .zero else {
            return NSSize(width: width, height: shortestHeight)
        }
        let height = min(max(parentWindowSize.height * parentHeightFraction, shortestHeight), tallestHeight)
        return NSSize(width: width, height: height)
    }
}
