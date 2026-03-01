import AppKit

extension NSCursor {
    static let rmbDiagonalResize: NSCursor = {
        guard let image = NSImage(named: "ResizeCursor") else {
            return NSCursor.arrow
        }

        let baseSize: CGFloat = 22
        image.size = NSSize(width: baseSize, height: baseSize)

        return NSCursor(
            image: image,
            hotSpot: NSPoint(x: baseSize / 2, y: baseSize / 2)
        )
    }()
}
