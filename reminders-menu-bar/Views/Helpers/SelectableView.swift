import SwiftUI

struct SelectableView: View {
    
    var title: String
    var isSelected: Bool
    var color: Color?
    var withPadding = true
    
    var body: some View {
        if isSelected {
            Image(systemName: "checkmark")
        }
        let paddingText = !isSelected && withPadding ? "      " : ""
        Text(paddingText + "● ")
            .foregroundColor(color)
        + Text(title)
    }
}

struct SelectableButton_Previews: PreviewProvider {
    static var previews: some View {
        SelectableView(title: "Option", isSelected: true)
    }
}
