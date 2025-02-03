import SwiftUI

struct ScrollableTextField: View {
    let title: String
    @Binding var text: String
    let maxHeight: CGFloat
    
    init(_ title: String, text: Binding<String>, maxHeight: CGFloat = 150) {
        self.title = title
        self._text = text
        self.maxHeight = maxHeight
    }
    
    var body: some View {
        if #available(macOS 13.0, *) {
            ZStack {
                // TextEditor placeholder
                VStack {
                    HStack {
                        Text(title)
                            .foregroundStyle(.tertiary)
                            .padding(.leading, 5)
                        Spacer(minLength: 0)
                    }
                }
                .opacity(text.isEmpty ? 1 : 0)
                
                TextEditor(text: $text)
                    .scrollContentBackground(.hidden)
                    .frame(maxHeight: maxHeight)
                    .fixedSize(horizontal: false, vertical: true)
            }
        } else {
            TextField(title, text: $text)
                .textFieldStyle(PlainTextFieldStyle())
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}

#Preview {
    ScrollableTextField("placeholder example", text: .constant(""))
}
