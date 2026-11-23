import Foundation
import Testing

/// One Objective-C member the header declares, reduced to what the runtime can check.
struct DeclaredMember: CustomTestStringConvertible, Sendable {
    enum Kind: Sendable {
        case instanceMethod
        case classMethod
    }

    let className: String
    let selectorName: String
    let kind: Kind
    /// The macOS version the declaration's `API_AVAILABLE` names, if any.
    let introducedVersion: OperatingSystemVersion?
    let headerLine: Int

    var testDescription: String {
        let prefix = kind == .classMethod ? "+" : "-"
        return "\(prefix)[\(className) \(selectorName)] (header line \(headerLine))"
    }
}

/// One `@interface` block of the header.
struct DeclaredClass: CustomTestStringConvertible, Sendable {
    let className: String
    let introducedVersion: OperatingSystemVersion?
    let members: [DeclaredMember]

    var testDescription: String { className }
}

/// Reads `OnBoardingKitPrivateAPI.h` the way the tests need it: every `@interface` of a class (not of a category),
/// every method and property inside it, and the `API_AVAILABLE(macos(…))` each one carries.
///
/// The parser relies on the header's own layout rules: a declaration ends with `;`, Swift-facing macros follow the
/// last parameter, and a class-level `API_AVAILABLE` sits on the line directly above `@interface`.
enum HeaderDeclarationParser {
    static let headerURL = URL(filePath: #filePath)
        .deletingLastPathComponent()
        .deletingLastPathComponent()
        .deletingLastPathComponent()
        .appending(path: "Sources/COnBoardingKit/include/OnBoardingKitPrivateAPI.h")

    static func parseClasses() throws -> [DeclaredClass] {
        let headerText = try String(contentsOf: headerURL, encoding: .utf8)
        let headerLines = headerText.components(separatedBy: "\n")

        var declaredClasses: [DeclaredClass] = []
        var currentClassName: String?
        var currentClassIntroducedVersion: OperatingSystemVersion?
        var currentMembers: [DeclaredMember] = []
        var pendingDeclaration = ""
        var pendingDeclarationLine = 0
        var isInsideComment = false

        for (lineIndex, rawLine) in headerLines.enumerated() {
            let lineNumber = lineIndex + 1
            var line = rawLine.trimmingCharacters(in: .whitespaces)

            if isInsideComment {
                if line.contains("*/") { isInsideComment = false }
                continue
            }
            if line.hasPrefix("/*") {
                if !line.contains("*/") { isInsideComment = true }
                continue
            }
            if let commentRange = line.range(of: "//") {
                line = String(line[..<commentRange.lowerBound]).trimmingCharacters(in: .whitespaces)
            }
            if line.isEmpty { continue }

            if currentClassName == nil {
                guard line.hasPrefix("@interface ") else { continue }
                let interfaceBody = line.dropFirst("@interface ".count)
                let className = interfaceBody.prefix(while: { $0.isLetter || $0.isNumber || $0 == "_" })
                // A category adds to a class declared elsewhere, and its members are checked through that class's
                // own tests; only `@interface Name : Superclass` opens a block checked here.
                guard interfaceBody.dropFirst(className.count).trimmingCharacters(in: .whitespaces).hasPrefix(":") else {
                    continue
                }
                currentClassName = String(className)
                currentClassIntroducedVersion = lineIndex > 0 ? introducedVersion(in: headerLines[lineIndex - 1]) : nil
                currentMembers = []
                continue
            }

            if line.hasPrefix("@end") {
                if let className = currentClassName {
                    declaredClasses.append(DeclaredClass(
                        className: className,
                        introducedVersion: currentClassIntroducedVersion,
                        members: currentMembers
                    ))
                }
                currentClassName = nil
                currentClassIntroducedVersion = nil
                continue
            }

            if pendingDeclaration.isEmpty {
                guard line.hasPrefix("-") || line.hasPrefix("+") || line.hasPrefix("@property") else { continue }
                pendingDeclarationLine = lineNumber
            }
            pendingDeclaration += (pendingDeclaration.isEmpty ? "" : " ") + line
            guard pendingDeclaration.hasSuffix(";") else { continue }

            currentMembers += members(
                fromDeclaration: pendingDeclaration,
                className: currentClassName!,
                headerLine: pendingDeclarationLine
            )
            pendingDeclaration = ""
        }
        return declaredClasses
    }

    /// The members one declaration contributes: one for a method, the getter and (unless read-only) the setter for a
    /// property.
    static func members(fromDeclaration declaration: String, className: String, headerLine: Int) -> [DeclaredMember] {
        let declarationIntroducedVersion = introducedVersion(in: declaration)
        let signature = signatureBeforeMacros(declaration)

        if signature.hasPrefix("@property") {
            let attributes = propertyAttributes(signature)
            let propertyName: String
            if let blockNameStart = signature.range(of: "(^")?.upperBound {
                // A block property names itself inside the declarator: `void (^name)(void)`.
                propertyName = String(signature[blockNameStart...].prefix(while: { $0.isLetter || $0.isNumber || $0 == "_" }))
            } else {
                propertyName = signature.split(whereSeparator: { !($0.isLetter || $0.isNumber || $0 == "_") }).last.map(String.init) ?? ""
            }
            let kind: DeclaredMember.Kind = attributes.contains("class") ? .classMethod : .instanceMethod
            let getterName = attributes.first(where: { $0.hasPrefix("getter=") })?.dropFirst("getter=".count).description ?? propertyName
            var propertyMembers = [DeclaredMember(
                className: className,
                selectorName: getterName,
                kind: kind,
                introducedVersion: declarationIntroducedVersion,
                headerLine: headerLine
            )]
            if !attributes.contains("readonly") {
                let setterName = attributes.first(where: { $0.hasPrefix("setter=") })?.dropFirst("setter=".count).description
                    ?? "set\(propertyName.prefix(1).uppercased())\(propertyName.dropFirst()):"
                propertyMembers.append(DeclaredMember(
                    className: className,
                    selectorName: setterName,
                    kind: kind,
                    introducedVersion: declarationIntroducedVersion,
                    headerLine: headerLine
                ))
            }
            return propertyMembers
        }

        let kind: DeclaredMember.Kind = signature.hasPrefix("+") ? .classMethod : .instanceMethod
        return [DeclaredMember(
            className: className,
            selectorName: selectorName(ofMethodSignature: signature),
            kind: kind,
            introducedVersion: declarationIntroducedVersion,
            headerLine: headerLine
        )]
    }

    /// The declaration up to the first trailing macro (`API_AVAILABLE`, `NS_SWIFT_NAME`, …) or the semicolon.
    static func signatureBeforeMacros(_ declaration: String) -> String {
        var signature = declaration
        if signature.hasSuffix(";") { signature.removeLast() }
        let macroMarkers = [" API_", " NS_", " __attribute__", " DEPRECATED", " UNAVAILABLE"]
        let firstMarker = macroMarkers.compactMap { signature.range(of: $0)?.lowerBound }.min()
        if let firstMarker { signature = String(signature[..<firstMarker]) }
        return signature.trimmingCharacters(in: .whitespaces)
    }

    /// `- (void)setTitle:(NSString *)title forState:(NSInteger)state` → `setTitle:forState:`.
    static func selectorName(ofMethodSignature signature: String) -> String {
        // Drop the leading "- (ReturnType)" or "+ (ReturnType)".
        var remainder = Substring(signature.dropFirst())
        remainder = remainder.drop(while: { $0 == " " })
        if remainder.first == "(" { remainder = skipParenthesizedGroup(remainder) }
        remainder = remainder.drop(while: { $0 == " " })

        guard remainder.contains(":") else {
            return String(remainder.prefix(while: { $0.isLetter || $0.isNumber || $0 == "_" }))
        }

        var selectorPieces: [String] = []
        var scanner = remainder
        while !scanner.isEmpty {
            scanner = scanner.drop(while: { $0 == " " })
            let keyword = scanner.prefix(while: { $0.isLetter || $0.isNumber || $0 == "_" })
            scanner = scanner.dropFirst(keyword.count).drop(while: { $0 == " " })
            guard scanner.first == ":" else { break }
            selectorPieces.append("\(keyword):")
            scanner = scanner.dropFirst().drop(while: { $0 == " " })
            if scanner.first == "(" { scanner = skipParenthesizedGroup(scanner) }
            // The parameter name.
            scanner = scanner.drop(while: { $0 == " " })
            scanner = scanner.drop(while: { $0.isLetter || $0.isNumber || $0 == "_" })
        }
        return selectorPieces.joined()
    }

    static func propertyAttributes(_ signature: String) -> [String] {
        guard let openParenthesis = signature.firstIndex(of: "("),
              signature[signature.startIndex..<openParenthesis].trimmingCharacters(in: .whitespaces) == "@property",
              let closeParenthesis = signature[openParenthesis...].firstIndex(of: ")")
        else { return [] }
        return signature[signature.index(after: openParenthesis)..<closeParenthesis]
            .split(separator: ",")
            .map { $0.trimmingCharacters(in: .whitespaces) }
    }

    /// The version in `API_AVAILABLE(macos(26.4))`, if the text carries one.
    static func introducedVersion(in text: String) -> OperatingSystemVersion? {
        guard let markerRange = text.range(of: "API_AVAILABLE(macos(") else { return nil }
        let versionText = text[markerRange.upperBound...].prefix(while: { $0.isNumber || $0 == "." })
        let components = versionText.split(separator: ".").compactMap { Int($0) }
        guard let majorVersion = components.first else { return nil }
        return OperatingSystemVersion(
            majorVersion: majorVersion,
            minorVersion: components.count > 1 ? components[1] : 0,
            patchVersion: components.count > 2 ? components[2] : 0
        )
    }

    private static func skipParenthesizedGroup(_ text: Substring) -> Substring {
        var depth = 0
        var index = text.startIndex
        while index < text.endIndex {
            if text[index] == "(" { depth += 1 }
            if text[index] == ")" {
                depth -= 1
                if depth == 0 { return text[text.index(after: index)...] }
            }
            index = text.index(after: index)
        }
        return text[text.endIndex...]
    }
}
