import AppKit

extension NSCursor {
    class var rmbDiagonalResize: NSCursor {
        guard let symbol = NSImage(
            systemSymbolName: "arrow.up.left.and.arrow.down.right",
            accessibilityDescription: nil
        ) else {
            return NSCursor.arrow
        }

        symbol.size = NSSize(width: 24, height: 24)
        symbol.isTemplate = true

        return NSCursor(image: symbol, hotSpot: NSPoint(x: symbol.size.width / 2, y: symbol.size.height / 2))
    }
}
