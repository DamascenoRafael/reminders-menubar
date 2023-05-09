import SwiftUI

struct FocusOnAppear: ViewModifier {
    let isEnabled: Bool
    
    init(isEnabled: Bool = true) {
        self.isEnabled = isEnabled
    }
    
    @ViewBuilder
    func body(content: Content) -> some View {
        if #available(macOS 12.0, *), isEnabled {
            content
                .modifier(FocusOnAppearWhenAvailable())
        } else {
            content
        }
    }
}

@available(macOS 12.0, *)
private struct FocusOnAppearWhenAvailable: ViewModifier {
    @FocusState private var textFieldInFocus: Bool
    
    func body(content: Content) -> some View {
        content
            .focused($textFieldInFocus)
            .onAppear {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    self.textFieldInFocus = true
                }
            }
    }
}
