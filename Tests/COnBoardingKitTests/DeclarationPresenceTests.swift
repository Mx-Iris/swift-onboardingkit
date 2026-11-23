import Foundation
import ObjectiveC
import Testing
import COnBoardingKit

/// Every class, method and property `OnBoardingKitPrivateAPI.h` declares exists on the system the tests run on.
///
/// The header is written by hand from the framework's runtime metadata, and the framework is private: macOS 27.2
/// removed members that 27.0 still had. A declaration that outlives its implementation compiles and links, and
/// fails only when called, with an unrecognized selector. These tests read the header itself, so a declaration added
/// later is covered without being listed here.
@Suite("Declarations match the running system")
struct DeclarationPresenceTests {
    static let declaredClasses: [DeclaredClass] = (try? HeaderDeclarationParser.parseClasses()) ?? []

    @Test("The header parses into classes and members")
    func headerParses() throws {
        let declaredClasses = try HeaderDeclarationParser.parseClasses()
        #expect(declaredClasses.count >= 29)
        #expect(declaredClasses.flatMap(\.members).count > 300)
    }

    @Test("Every declared class exists", arguments: declaredClasses)
    func classExists(_ declaredClass: DeclaredClass) {
        guard isAvailableOnRunningSystem(declaredClass.introducedVersion) else { return }
        #expect(NSClassFromString(declaredClass.className) != nil, "\(declaredClass.className) is not registered")
    }

    @Test("Every declared method and property accessor exists", arguments: declaredClasses)
    func membersExist(_ declaredClass: DeclaredClass) throws {
        guard isAvailableOnRunningSystem(declaredClass.introducedVersion) else { return }
        let runtimeClass: AnyClass = try #require(NSClassFromString(declaredClass.className))
        for member in declaredClass.members where isAvailableOnRunningSystem(member.introducedVersion) {
            let selector = NSSelectorFromString(member.selectorName)
            let responds = switch member.kind {
            case .instanceMethod:
                runtimeClass.instancesRespond(to: selector)
            case .classMethod:
                (runtimeClass as AnyObject).responds(to: selector)
            }
            #expect(responds, "\(member.testDescription) is missing on this system")
        }
    }

    @Test("The parser reads selectors, properties and availability")
    func parserReadsDeclarations() {
        let methodMembers = HeaderDeclarationParser.members(
            fromDeclaration: "- (void)addItemWithTitle:(NSString *)title description:(nullable NSString *)description symbol:(NSString *)symbol symbolTintColor:(nullable NSColor *)symbolTintColor status:(nullable NSString *)status API_AVAILABLE(macos(15.0)) NS_SWIFT_NAME(addItem(title:description:symbolName:symbolTintColor:status:));",
            className: "OBTemplatePartBulletList",
            headerLine: 1
        )
        #expect(methodMembers.map(\.selectorName) == ["addItemWithTitle:description:symbol:symbolTintColor:status:"])
        #expect(methodMembers.first?.introducedVersion?.majorVersion == 15)

        let blockMembers = HeaderDeclarationParser.members(
            fromDeclaration: "- (void)fadeTitleToAlpha:(CGFloat)alpha duration:(NSTimeInterval)duration completionHandler:(nullable void (^)(void))completionHandler;",
            className: "OBTemplateView",
            headerLine: 1
        )
        #expect(blockMembers.map(\.selectorName) == ["fadeTitleToAlpha:duration:completionHandler:"])

        let propertyMembers = HeaderDeclarationParser.members(
            fromDeclaration: "@property (nonatomic, getter=isPersonallyIdentifiable, readonly) BOOL personallyIdentifiable;",
            className: "OBPrivacyFlow",
            headerLine: 1
        )
        #expect(propertyMembers.map(\.selectorName) == ["isPersonallyIdentifiable"])

        let classPropertyMembers = HeaderDeclarationParser.members(
            fromDeclaration: "@property (class, nonatomic, readonly, copy) NSString *linkPlaceholder;",
            className: "OBPrivacyCombinedFooterComponents",
            headerLine: 1
        )
        #expect(classPropertyMembers.map(\.selectorName) == ["linkPlaceholder"])
        #expect(classPropertyMembers.first?.kind == .classMethod)

        let readWriteMembers = HeaderDeclarationParser.members(
            fromDeclaration: "@property (nonatomic, nullable, strong) NSImage *topImage;",
            className: "OBTemplateView",
            headerLine: 1
        )
        #expect(readWriteMembers.map(\.selectorName) == ["topImage", "setTopImage:"])
    }

    private func isAvailableOnRunningSystem(_ introducedVersion: OperatingSystemVersion?) -> Bool {
        guard let introducedVersion else { return true }
        return ProcessInfo.processInfo.isOperatingSystemAtLeast(introducedVersion)
    }
}
