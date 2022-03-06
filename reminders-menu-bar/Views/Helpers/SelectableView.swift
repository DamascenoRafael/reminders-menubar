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
        
        let paddingText = !isSelected && withPadding ? "      " : ""
        let coloredDot = color != nil ? Text("●  ").foregroundColor(color) : Text("")
        
        Group {
            Text(paddingText).font(.system(size: 11.9)) +
            coloredDot +
            Text(title)
        }
    }
}

struct SelectableButton_Previews: PreviewProvider {
    static var previews: some View {
        SelectableView(title: "Option", isSelected: true)
    }
}
