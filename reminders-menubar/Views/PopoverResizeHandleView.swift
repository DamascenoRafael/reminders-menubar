import SwiftUI
import AppKit

struct PopoverResizeHandleView: View {
    @Environment(\.colorSchemeContrast) private var colorSchemeContrast

    @State private var isHovering = false
    @State private var isDragging = false
    @State private var dragStartSize: CGSize?

    private var shouldShowResizeCursor: Bool {
        isHovering || isDragging
    }

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
        }
        .onChange(of: shouldShowResizeCursor) { showCursor in
            if showCursor {
                NSCursor.rmbDiagonalResize.push()
            } else {
                NSCursor.pop()
            }
        }
        .onDisappear {
            if shouldShowResizeCursor {
                NSCursor.pop()
            }
        }
        .animation(.easeOut(duration: 0.12), value: isHovering)
        .gesture(
            DragGesture(minimumDistance: 0, coordinateSpace: .global)
                .onChanged { value in
                    if dragStartSize == nil {
                        isDragging = true
                        dragStartSize = AppDelegate.shared.popover.contentSize
                    }

                    guard let startSize = dragStartSize else { return }
                    let newSize = NSSize(
                        width: startSize.width + value.translation.width,
                        height: startSize.height + value.translation.height
                    )
                    AppDelegate.shared.setMainPopoverSize(size: newSize, persist: false)
                }
                .onEnded { value in
                    let startSize = dragStartSize ?? AppDelegate.shared.popover.contentSize
                    let newSize = NSSize(
                        width: startSize.width + value.translation.width,
                        height: startSize.height + value.translation.height
                    )
                    AppDelegate.shared.setMainPopoverSize(size: newSize, persist: true)
                    dragStartSize = nil
                    isDragging = false
                }
        )
        .help("Drag to resize")
        .accessibilityLabel("Resize window")
    }
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
