import SwiftUI

// Workaround to present the list without the background transparency
// https://stackoverflow.com/questions/60454752/swiftui-background-color-of-list-mac-os

extension NSTableView {
    open override func viewDidMoveToWindow() {
        super.viewDidMoveToWindow()
        
        backgroundColor = NSColor.clear
        enclosingScrollView?.drawsBackground = false
    }
}
