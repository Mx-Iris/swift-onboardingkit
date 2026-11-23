import AppKit
import COnBoardingKit

extension OBPrivacyPresenter {
    /// Shows the privacy page as a sheet on `window` and returns once the sheet has ended.
    ///
    /// Sets `presentingWindow` to `window`. While the sheet is up, `dismissHandler` is replaced; when the sheet ends,
    /// the handler you had set is put back and called before this method returns.
    ///
    /// Do not call it again on the same presenter before it returns: the second call takes over `dismissHandler`, and
    /// the first never returns.
    ///
    /// ```swift
    /// if let presenter = OBPrivacyPresenter(splashFor: .appStore) {
    ///     await presenter.presentAsSheet(on: window)
    /// }
    /// ```
    public func presentAsSheet(on window: NSWindow) async {
        presentingWindow = window
        let previousDismissHandler = dismissHandler
        await withCheckedContinuation { (continuation: CheckedContinuation<Void, Never>) in
            dismissHandler = { [weak self] in
                self?.dismissHandler = previousDismissHandler
                previousDismissHandler?()
                continuation.resume()
            }
            present()
        }
    }
}
