import SwiftUI

enum ColoredDotTitle {
    private static let dotPrefix = "●"
    private static let spacing = "  "

    static func text(_ title: String, color: Color) -> Text {
        Text(verbatim: dotPrefix).foregroundColor(color) + Text(spacing) + Text(title)
    }

    static func attributedString(_ title: String, color: NSColor, prefix: String = dotPrefix) -> NSAttributedString {
        let result = NSMutableAttributedString()
        let prefixAttributes: [NSAttributedString.Key: Any] = [
            .foregroundColor: color,
            .font: NSFont.monospacedSystemFont(ofSize: NSFont.systemFontSize, weight: .regular)
        ]
        result.append(NSAttributedString(string: prefix, attributes: prefixAttributes))
        result.append(NSAttributedString(string: spacing))
        result.append(NSAttributedString(string: title))
        return result
    }
}
