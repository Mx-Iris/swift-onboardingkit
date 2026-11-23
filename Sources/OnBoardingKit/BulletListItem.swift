import AppKit
import COnBoardingKit

extension OBTemplatePartBulletList {
    /// The image at the leading edge of a bullet list row.
    public enum ItemImage: Sendable {
        /// An SF Symbol, by name.
        case systemImage(String)
        /// An image of your own.
        case image(NSImage)
    }

    /// One row of a bullet list: an image, a title, a description and a status line, each optional.
    ///
    /// A row with sub-items becomes an expandable row: clicking it shows the sub-items below it.
    public struct Item: Sendable {
        public var title: String?
        public var description: String?
        public var image: ItemImage?
        /// The color the image is tinted with. `nil` uses the framework's default, the accent color.
        public var tintColor: NSColor?
        /// A short line under the description, such as "On" or "Requires an Apple Account".
        public var status: String?
        /// The rows an expandable row shows when expanded. Empty for an ordinary row.
        public var subitems: [Item]

        /// A row with an SF Symbol.
        public init(
            _ title: String? = nil,
            description: String? = nil,
            systemImage: String,
            tintColor: NSColor? = nil,
            status: String? = nil,
            @OBTemplatePartBulletList.ItemBuilder subitems: () -> [Item] = { [] }
        ) {
            self.title = title
            self.description = description
            self.image = .systemImage(systemImage)
            self.tintColor = tintColor
            self.status = status
            self.subitems = subitems()
        }

        /// A row with an image of your own.
        public init(
            _ title: String? = nil,
            description: String? = nil,
            image: NSImage,
            tintColor: NSColor? = nil,
            status: String? = nil,
            @OBTemplatePartBulletList.ItemBuilder subitems: () -> [Item] = { [] }
        ) {
            self.title = title
            self.description = description
            self.image = .image(image)
            self.tintColor = tintColor
            self.status = status
            self.subitems = subitems()
        }

        /// A row without an image.
        public init(
            _ title: String? = nil,
            description: String? = nil,
            status: String? = nil,
            @OBTemplatePartBulletList.ItemBuilder subitems: () -> [Item] = { [] }
        ) {
            self.title = title
            self.description = description
            self.image = nil
            self.tintColor = nil
            self.status = status
            self.subitems = subitems()
        }
    }

    /// Collects the rows of a bullet list written one after another, with `if`, `if let`, `switch` and `for`.
    @resultBuilder
    public enum ItemBuilder {
        public static func buildExpression(_ item: Item) -> [Item] { [item] }
        public static func buildExpression(_ items: [Item]) -> [Item] { items }
        public static func buildBlock(_ components: [Item]...) -> [Item] { components.flatMap(\.self) }
        public static func buildOptional(_ component: [Item]?) -> [Item] { component ?? [] }
        public static func buildEither(first component: [Item]) -> [Item] { component }
        public static func buildEither(second component: [Item]) -> [Item] { component }
        public static func buildArray(_ components: [[Item]]) -> [Item] { components.flatMap(\.self) }
        public static func buildLimitedAvailability(_ component: [Item]) -> [Item] { component }
    }

    /// A bullet list with the rows the builder lists, in order.
    ///
    /// ```swift
    /// let features = OBTemplatePartBulletList {
    ///     OBTemplatePartBulletList.Item("Faster Search", description: "Results appear as you type.", systemImage: "magnifyingglass")
    ///     OBTemplatePartBulletList.Item("Shared Boards", description: "Invite others to edit with you.", systemImage: "person.2")
    /// }
    /// ```
    public convenience init(@ItemBuilder items: () -> [Item]) {
        self.init(frame: .zero)
        addItems(items())
    }

    /// Appends one row.
    public func addItem(_ item: Item) {
        guard item.subitems.isEmpty else {
            let sublistItems = item.subitems.map(OBTemplatePartBulletListItem.init(item:))
            switch item.image {
            case .systemImage(let symbolName):
                addExpandableItem(withTitle: item.title, description: item.description, symbol: symbolName, imageTintColor: item.tintColor, status: item.status, sublistItems: sublistItems)
            case .image(let image):
                addExpandableItem(withTitle: item.title, description: item.description, image: image, imageTintColor: item.tintColor, status: item.status, sublistItems: sublistItems)
            case nil:
                addExpandableItem(withTitle: item.title, description: item.description, image: nil, imageTintColor: item.tintColor, status: item.status, sublistItems: sublistItems)
            }
            return
        }
        switch (item.image, item.title) {
        case (.systemImage(let symbolName), .some(let title)):
            addItem(withTitle: title, description: item.description, symbol: symbolName, symbolTintColor: item.tintColor, status: item.status)
        case (.systemImage(let symbolName), nil):
            addItem(withDescription: item.description, symbol: symbolName, symbolTintColor: item.tintColor, status: item.status)
        case (.image(let image), .some(let title)):
            addItem(withTitle: title, description: item.description, image: image, imageTintColor: item.tintColor, status: item.status)
        case (.image(let image), nil):
            addItem(withDescription: item.description, image: image, imageTintColor: item.tintColor, status: item.status)
        case (nil, let title):
            addItem(withTitle: title, description: item.description, image: nil, imageTintColor: item.tintColor, status: item.status)
        }
    }

    /// Appends rows, in order.
    public func addItems(_ items: [Item]) {
        for item in items {
            addItem(item)
        }
    }

    /// Appends the rows the builder lists, in order.
    public func addItems(@ItemBuilder _ items: () -> [Item]) {
        addItems(items())
    }
}

extension OBTemplatePartBulletListItem {
    /// A stand-alone row view, as an expandable row's sub-item uses it.
    @MainActor
    public convenience init(item: OBTemplatePartBulletList.Item) {
        switch item.image {
        case .systemImage(let symbolName):
            self.init(title: item.title, description: item.description, symbol: symbolName, symbolTintColor: item.tintColor, spacing: .default, status: item.status, showsBackground: false)
        case .image(let image):
            self.init(title: item.title, description: item.description, image: image, imageTintColor: item.tintColor, spacing: .default, status: item.status, showsBackground: false)
        case nil:
            self.init(title: item.title, description: item.description, image: nil, imageTintColor: item.tintColor, spacing: .default, status: item.status, showsBackground: false)
        }
    }
}
