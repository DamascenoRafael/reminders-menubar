import SwiftUI

enum ColoredDotTitle {
    private static let dotPrefix = "●  "

    static func text(_ title: String, color: Color) -> Text {
        Text(verbatim: dotPrefix).foregroundColor(color) + Text(title)
    }

    static func attributedString(_ title: String, color: NSColor) -> NSAttributedString {
        let result = NSMutableAttributedString()
        result.append(NSAttributedString(string: dotPrefix, attributes: [.foregroundColor: color]))
        result.append(NSAttributedString(string: title))
        return result
    }
}
