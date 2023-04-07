import SwiftUI

extension NSTableView {
    open override func viewDidMoveToWindow() {
        super.viewDidMoveToWindow()
        
        // Workaround to present the list without the background transparency
        // https://stackoverflow.com/questions/60454752/swiftui-background-color-of-list-mac-os
        backgroundColor = NSColor.clear
        enclosingScrollView?.drawsBackground = false
        
        // Removing sticky section header
        floatsGroupRows = false
    }
}
