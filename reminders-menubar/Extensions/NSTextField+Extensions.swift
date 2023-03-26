import SwiftUI

// Workaround to remove focus ring highlight border from textfield (on macOS Big Sur)
// https://stackoverflow.com/questions/59813943/swiftui-remove-focus-ring-highlight-border-from-macos-textfield

extension NSTextField {
    open override var focusRingType: NSFocusRingType {
        get { .none }
        set { }
    }
}
