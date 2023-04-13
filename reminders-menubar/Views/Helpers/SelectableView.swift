import SwiftUI

struct SelectableView: View {
    var title: String
    var isSelected: Bool
    var color: Color?
    var withPadding = true
    
    var body: some View {
        if isSelected {
            Image(systemName: "checkmark")
        } else if withPadding {
            Image(nsImage: NSImage(named: "empty")!)
        }
        
        let coloredDot = color != nil ? Text("●  ").foregroundColor(color) : Text("")
        
        Group {
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
