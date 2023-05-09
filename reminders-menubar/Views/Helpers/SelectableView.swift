import SwiftUI

struct SelectableView: View {
    var title: String
    var isSelected: Bool
    var color: Color?
    var withPadding: Bool
    
    init(title: String, isSelected: Bool, color: Color? = nil, withPadding: Bool = true) {
        self.title = title
        self.isSelected = isSelected
        self.color = color
        self.withPadding = withPadding
    }
    
    init(title: String, color: Color) {
        self.title = title
        self.color = color
        self.isSelected = false
        self.withPadding = false
    }
    
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
