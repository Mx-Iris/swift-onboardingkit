import AppKit
import Testing
import OnBoardingKit

@MainActor
@Suite("Bullet list builder")
struct BulletListBuilderTests {
    @Test("Rows are added in the order the builder lists them")
    func rowsKeepTheirOrder() throws {
        let bulletList = OBTemplatePartBulletList {
            OBTemplatePartBulletList.Item("First", description: "One", systemImage: "1.circle")
            OBTemplatePartBulletList.Item("Second", description: "Two", systemImage: "2.circle")
            OBTemplatePartBulletList.Item("Third", description: "Three", image: NSImage(size: NSSize(width: 16, height: 16)))
        }
        let rows = try rowViews(of: bulletList)
        #expect(rows.count == 3)
        #expect(rows.map { $0.titleLabel?.stringValue } == ["First", "Second", "Third"])
        #expect(rows.map { $0.descriptionLabel?.stringValue } == ["One", "Two", "Three"])
    }

    @Test("Conditions and loops in the builder add exactly the rows they produce")
    func controlFlowProducesRows() throws {
        let includesOptionalRow = false
        let numberedTitles = ["Alpha", "Beta"]
        let bulletList = OBTemplatePartBulletList {
            OBTemplatePartBulletList.Item("Always", systemImage: "star")
            if includesOptionalRow {
                OBTemplatePartBulletList.Item("Never", systemImage: "xmark")
            }
            for title in numberedTitles {
                OBTemplatePartBulletList.Item(title, systemImage: "circle")
            }
        }
        let rows = try rowViews(of: bulletList)
        #expect(rows.map { $0.titleLabel?.stringValue } == ["Always", "Alpha", "Beta"])
    }

    @Test("A row with a status shows it under the description")
    func statusIsShown() throws {
        let bulletList = OBTemplatePartBulletList {
            OBTemplatePartBulletList.Item("Sync", description: "Keep notes up to date.", systemImage: "icloud", status: "On")
        }
        let row = try #require(try rowViews(of: bulletList).first)
        #expect(row.statusLabel?.stringValue == "On")
    }

    @Test("A row with sub-items becomes an expandable row holding them")
    func subitemsMakeAnExpandableRow() throws {
        let bulletList = OBTemplatePartBulletList {
            OBTemplatePartBulletList.Item("Privacy", description: "What is shared.", systemImage: "hand.raised") {
                OBTemplatePartBulletList.Item("Location", systemImage: "location")
                OBTemplatePartBulletList.Item("Contacts", systemImage: "person.crop.circle")
            }
        }
        let stack = try #require(bulletList.stack)
        let expandableRow = try #require(stack.arrangedSubviews.compactMap { $0 as? OBTemplatePartBulletExpandableListItem }.first)
        #expect(expandableRow.listItem?.titleLabel?.stringValue == "Privacy")
        // The row keeps its sub-items aside until it is expanded.
        let expandableStack = try #require(expandableRow.expandableStack)
        #expect(expandableStack.arrangedSubviews.isEmpty)
        expandableRow.expanded = true
        let subitemTitles = expandableStack.arrangedSubviews
            .compactMap { $0 as? OBTemplatePartBulletListItem }
            .map { $0.titleLabel?.stringValue }
        #expect(subitemTitles == ["Location", "Contacts"])
    }

    @Test("addItems appends after the rows already there")
    func addItemsAppends() throws {
        let bulletList = OBTemplatePartBulletList {
            OBTemplatePartBulletList.Item("Existing", systemImage: "star")
        }
        bulletList.addItems {
            OBTemplatePartBulletList.Item("Added", systemImage: "plus")
        }
        #expect(try rowViews(of: bulletList).map { $0.titleLabel?.stringValue } == ["Existing", "Added"])
    }

    private func rowViews(of bulletList: OBTemplatePartBulletList) throws -> [OBTemplatePartBulletListItem] {
        let stack = try #require(bulletList.stack)
        return stack.arrangedSubviews.compactMap { $0 as? OBTemplatePartBulletListItem }
    }
}
