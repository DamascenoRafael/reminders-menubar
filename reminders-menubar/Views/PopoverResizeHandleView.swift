import SwiftUI
import AppKit

struct PopoverResizeHandleView: View {
    @Environment(\.colorSchemeContrast) private var colorSchemeContrast

    @State private var dragStartSize: CGSize?
    @State private var isHovering = false

    var body: some View {
        ZStack {
            CornerArcGrabber()
                .stroke(
                    Color.rmbColor(for: .borderContrast, and: colorSchemeContrast).opacity(isHovering ? 0.85 : 0.35),
                    style: StrokeStyle(lineWidth: 1.3, lineCap: .round)
                )
                .background(
                    CornerArcGrabber()
                        .stroke(
                            isHovering ? Color.rmbColor(for: .buttonHover, and: colorSchemeContrast) : .clear,
                            style: StrokeStyle(lineWidth: 9.0, lineCap: .round)
                        )
                )
                .padding(4)
        }
        .frame(width: 22, height: 22)
        .contentShape(Rectangle())
        .onHover { hovering in
            isHovering = hovering
            if hovering {
                Self.diagonalResizeCursor.push()
            } else {
                NSCursor.pop()
            }
        }
        .onDisappear {
            // Defensive cursor cleanup if the view disappears while hovered.
            if isHovering {
                NSCursor.pop()
                isHovering = false
            }
        }
        .animation(.easeOut(duration: 0.12), value: isHovering)
        .gesture(
            DragGesture(minimumDistance: 0, coordinateSpace: .global)
                .onChanged { value in
                    if dragStartSize == nil {
                        dragStartSize = AppDelegate.shared.popover.contentSize
                    }

                    guard let startSize = dragStartSize else { return }
                    let newWidth = startSize.width + value.translation.width
                    let newHeight = startSize.height + value.translation.height
                    AppDelegate.shared.setMainPopoverSize(width: newWidth, height: newHeight, persist: false)
                }
                .onEnded { value in
                    let startSize = dragStartSize ?? AppDelegate.shared.popover.contentSize
                    let newWidth = startSize.width + value.translation.width
                    let newHeight = startSize.height + value.translation.height
                    AppDelegate.shared.setMainPopoverSize(width: newWidth, height: newHeight, persist: true)
                    dragStartSize = nil
                }
        )
        .help("Drag to resize")
        .accessibilityLabel("Resize window")
    }

    private static let diagonalResizeCursor: NSCursor = {
        // AppKit doesn't provide a public diagonal resize cursor across all supported macOS versions.
        // Provide our own from an SF Symbol so the cursor matches the corner handle.
        let fallback = NSCursor.resizeUpDown

        guard let symbol = NSImage(
            systemSymbolName: "arrow.up.left.and.arrow.down.right",
            accessibilityDescription: nil
        ) else {
            return fallback
        }

        let size = NSSize(width: 24, height: 24)
        symbol.size = size
        symbol.isTemplate = true

        // Center hotspot feels the most natural for this symbol.
        return NSCursor(image: symbol, hotSpot: NSPoint(x: size.width / 2, y: size.height / 2))
    }()
}

private struct CornerArcGrabber: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()

        // A single arc that reads as a rounded corner in the bottom-right.
        let radius = min(rect.width, rect.height)
        let start = CGPoint(x: rect.maxX - radius, y: rect.maxY)
        let end = CGPoint(x: rect.maxX, y: rect.maxY - radius)
        let control = CGPoint(x: rect.maxX, y: rect.maxY)

        path.move(to: start)
        path.addQuadCurve(to: end, control: control)

        return path
    }
}
