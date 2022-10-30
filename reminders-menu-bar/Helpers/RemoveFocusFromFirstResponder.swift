import SwiftUI

func removeFocusFromFirstResponder() {
    DispatchQueue.main.async {
        NSApp.keyWindow?.makeFirstResponder(nil)
    }
}
