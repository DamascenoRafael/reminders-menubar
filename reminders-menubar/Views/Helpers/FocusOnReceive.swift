import SwiftUI

struct FocusOnReceive: ViewModifier {
    let publisher: Published<Bool>.Publisher
    
    init(_ publisher: Published<Bool>.Publisher) {
        self.publisher = publisher
    }
    
    @ViewBuilder
    func body(content: Content) -> some View {
        if #available(macOS 12.0, *) {
            content
                .modifier(FocusOnReceiveWhenAvailable(publisher: publisher))
        } else {
            content
        }
    }
}

@available(macOS 12.0, *)
private struct FocusOnReceiveWhenAvailable: ViewModifier {
    let publisher: Published<Bool>.Publisher
    @FocusState private var textFieldInFocus: Bool
    
    func body(content: Content) -> some View {
        content
            .focused($textFieldInFocus)
            .onReceive(publisher) { _ in
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    self.textFieldInFocus = true
                }
            }
    }
}
