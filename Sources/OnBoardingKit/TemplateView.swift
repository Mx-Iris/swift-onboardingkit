import AppKit
import COnBoardingKit

extension OBTemplateView {
    /// A template with an SF Symbol above the title, the body text under it, and an optional view under the text.
    ///
    /// - Parameters:
    ///   - title: The page title.
    ///   - bodyText: Plain text under the title. Use `attributedBodyText` for text with attributes.
    ///   - systemImage: The name of the SF Symbol above the title, or `nil` for none.
    ///   - layoutStyle: What the template builds around the title. It is read only now, while the view is created.
    ///   - contentArea: The view under the body text, usually an `OBTemplatePartBulletList`.
    public convenience init(
        title: String,
        bodyText: String? = nil,
        systemImage: String? = nil,
        layoutStyle: OBTemplateLayoutStyle = .default,
        contentArea: NSView? = nil
    ) {
        self.init(title: title, bodyText: bodyText, symbol: systemImage, contentLayoutStyle: layoutStyle)
        if let contentArea {
            self.contentArea = contentArea
        }
    }

    /// A "What's New" page: an SF Symbol, a title, body text, and a bullet list with the rows the builder lists.
    ///
    /// ```swift
    /// let templateView = OBTemplateView(title: "What's New in Notes", systemImage: "note.text") {
    ///     OBTemplatePartBulletList.Item("Audio Transcripts", description: "Record and transcribe in a note.", systemImage: "waveform")
    ///     OBTemplatePartBulletList.Item("Math Notes", description: "Solve expressions as you type.", systemImage: "x.squareroot")
    /// }
    /// ```
    ///
    /// The bullet list is the template's `contentArea`.
    public convenience init(
        title: String,
        bodyText: String? = nil,
        systemImage: String? = nil,
        layoutStyle: OBTemplateLayoutStyle = .default,
        @OBTemplatePartBulletList.ItemBuilder features: () -> [OBTemplatePartBulletList.Item]
    ) {
        self.init(
            title: title,
            bodyText: bodyText,
            systemImage: systemImage,
            layoutStyle: layoutStyle,
            contentArea: OBTemplatePartBulletList(items: features)
        )
    }

    /// The bullet list this template shows as its content area, if that is what it shows.
    public var bulletList: OBTemplatePartBulletList? {
        contentArea as? OBTemplatePartBulletList
    }
}
