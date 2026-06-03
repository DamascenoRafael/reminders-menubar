import SwiftUI

enum ColoredDotTitle {
    private static let dotPrefix = "●"
    private static let spacing = "  "

    static func text(_ title: String, color: Color, prefix: String = dotPrefix) -> Text {
        Text(verbatim: prefix)
            .foregroundColor(color)
            .font(.system(size: NSFont.systemFontSize, design: .monospaced))
        + Text(spacing) + Text(title)
    }
}
