import AppKit
import COnBoardingKit

/// A welcome or "What's New" page as values: what the template shows and how it is laid out. Assemble it with
/// ``OBTemplateContainerViewController/init(page:primaryButton:secondaryButton:cancelButton:)``.
///
/// ```swift
/// let page = OBTemplatePage(title: "What's New in Atlas", image: .systemImage("map")) {
///     OBTemplatePartBulletList.Item("Offline Maps", description: "Use a region without a connection.", systemImage: "arrow.down.circle")
///     OBTemplatePartBulletList.Item("Shared Trips", description: "Plan a route together.", systemImage: "person.2")
/// }
/// let controller = OBTemplateContainerViewController(page: page, primaryButton: .init("Continue") { $0.dismiss(nil) })
/// window.contentViewController?.presentAsSheet(controller)
/// ```
///
/// Nothing here is a view: the template view, its bullet list and the container are made when the page is assembled,
/// and each assembly makes new ones.
public struct OBTemplatePage {
    /// The image above the title.
    public enum Image {
        /// An SF Symbol, by name.
        case systemImage(String)
        /// An image of your own, such as the app's icon. Give it the size it should have on the page.
        case image(NSImage)
    }

    /// The page's side margins, and where its image sits.
    ///
    /// The framework decides both by the template's type (`OBTemplateType`) and `needsExtraWideContent`; a layout sets
    /// them on the template and on its bullet list, which does not take them from the template.
    public struct Layout: Hashable, Sendable {
        /// 175-point side margins, for a page that fills a whole window, as the framework's own setup pages do. The
        /// image leads the text.
        public static let standard = Layout(templateType: .standard, needsExtraWideContent: false)
        /// 85-point side margins. The image leads the text.
        public static let wide = Layout(templateType: .standard, needsExtraWideContent: true)
        /// 68-point side margins with the image centered above the text, and bullet rows 344 points wide: the width a
        /// 482-point sheet leaves. What the App Store's welcome and "What's New" sheets use.
        public static let centered = Layout(templateType: .centered, needsExtraWideContent: false)
        /// The privacy pages' shape: 68-point side margins, the content in a scroll view of its own under the title,
        /// and a top margin of 12 % of the window's height.
        public static let privacy = Layout(templateType: .privacy, needsExtraWideContent: false)

        let templateType: OBTemplateType
        let needsExtraWideContent: Bool
    }

    public var title: String
    public var bodyText: String?
    public var image: Image?
    /// The rows of the bullet list under the body text. With none, the page has no bullet list.
    public var features: [OBTemplatePartBulletList.Item]
    /// The color of the images of the rows that set no `tintColor` of their own. `nil` leaves them to the framework.
    public var featureTintColor: NSColor?
    /// The row metrics of the bullet list.
    public var featureSpacing: OBBulletListSpacing
    public var layout: Layout
    /// The size the page opens at, as a window or as a sheet. The framework's own sheets are
    /// `OBTemplateContainerViewController.sheetSize(forParentWindowSize:)`; the default is that size with no parent
    /// window.
    public var size: NSSize

    /// A page with the rows the array lists.
    public init(
        title: String,
        bodyText: String? = nil,
        image: Image? = nil,
        features: [OBTemplatePartBulletList.Item] = [],
        featureTintColor: NSColor? = nil,
        featureSpacing: OBBulletListSpacing = .default,
        layout: Layout = .centered,
        size: NSSize = OBTemplateContainerViewController.sheetSize()
    ) {
        self.title = title
        self.bodyText = bodyText
        self.image = image
        self.features = features
        self.featureTintColor = featureTintColor
        self.featureSpacing = featureSpacing
        self.layout = layout
        self.size = size
    }

    /// A page with the rows the builder lists.
    public init(
        title: String,
        bodyText: String? = nil,
        image: Image? = nil,
        featureTintColor: NSColor? = nil,
        featureSpacing: OBBulletListSpacing = .default,
        layout: Layout = .centered,
        size: NSSize = OBTemplateContainerViewController.sheetSize(),
        @OBTemplatePartBulletList.ItemBuilder features: () -> [OBTemplatePartBulletList.Item]
    ) {
        self.init(
            title: title,
            bodyText: bodyText,
            image: image,
            features: features(),
            featureTintColor: featureTintColor,
            featureSpacing: featureSpacing,
            layout: layout,
            size: size
        )
    }
}

extension OBTemplateContainerViewController {
    /// A controller showing `page` above a tray with a primary button and, optionally, a secondary and a cancel button,
    /// each calling its action when clicked. It opens at the page's size.
    ///
    /// The template view, its bullet list and the controller are made here, from the page's values; nothing of the page
    /// needs setting on them afterwards.
    public convenience init(
        page: OBTemplatePage,
        primaryButton: Button,
        secondaryButton: Button? = nil,
        cancelButton: Button? = nil
    ) {
        let bulletList = page.features.isEmpty ? nil : OBTemplatePartBulletList(features: page.features, of: page)
        let templateView: OBTemplateView
        switch page.image {
        case .systemImage(let symbolName):
            templateView = OBTemplateView(title: page.title, bodyText: page.bodyText, systemImage: symbolName, contentArea: bulletList)
        case .image(let image):
            templateView = OBTemplateView(title: page.title, bodyText: page.bodyText, icon: image, contentLayoutStyle: .default)
            if let bulletList {
                templateView.contentArea = bulletList
            }
        case nil:
            templateView = OBTemplateView(title: page.title, bodyText: page.bodyText, contentArea: bulletList)
        }
        self.init(templateView: templateView, primaryButton: primaryButton, secondaryButton: secondaryButton, cancelButton: cancelButton)
        // After the initializer, which turns a standard template centered; the template reads its type when it first
        // draws.
        templateView.templateType = page.layout.templateType
        templateView.needsExtraWideContent = page.layout.needsExtraWideContent
        bulletList?.apply(page.layout)
        preferredContentSize = page.size
    }
}

extension OBTemplatePartBulletList {
    /// The page's bullet list. The spacing and the layout come first: a row takes the list's metrics when it is added.
    fileprivate convenience init(features: [Item], of page: OBTemplatePage) {
        self.init(frame: .zero)
        bulletListSpacing = page.featureSpacing
        apply(page.layout)
        for feature in features {
            var feature = feature
            if feature.tintColor == nil {
                feature.tintColor = page.featureTintColor
            }
            addItem(feature)
        }
    }

    fileprivate func apply(_ layout: OBTemplatePage.Layout) {
        templateType = layout.templateType
        needsExtraWideContent = layout.needsExtraWideContent
    }
}
