import SwiftUI

struct SelectableView: View {
    
    var title: String
    var isSelected: Bool
    var color: Color?
    var withPadding = true
    var withDot = false
    
    var body: some View {
        if isSelected {
            Image(systemName: "checkmark")
                .frame(minWidth: 0, minHeight: 0)
        }
        let paddingText = !isSelected && withPadding ? "      " : ""
        if withDot{
            Text(paddingText + "● ")
                .foregroundColor(color)
            + Text(title)
        }else{
            Text(paddingText+title)
        }
    }
}

struct SelectableButton_Previews: PreviewProvider {
    static var previews: some View {
        HStack{SelectableView(title: "Option", isSelected: true, withDot: true)}
        HStack{SelectableView(title: "Option", isSelected: false, withDot: true)}
    }
}
