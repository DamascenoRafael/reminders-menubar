import SwiftUI

struct RmbDatePicker: NSViewRepresentable {
    @Binding var selection: Date
    var displayedComponents: NSDatePicker.ElementFlags
    var font: NSFont?

    func makeNSView(context: Context) -> NSDatePicker {
        let picker = NSDatePicker()
        picker.font = font ?? picker.font
        picker.isBordered = false
        picker.datePickerStyle = .textField
        picker.presentsCalendarOverlay = true
        picker.datePickerElements = displayedComponents
        picker.action = #selector(Coordinator.onValueChange(_:))
        picker.target = context.coordinator
        return picker
    }

    func updateNSView(_ picker: NSDatePicker, context: Context) {
        picker.dateValue = selection
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(owner: self)
    }

    class Coordinator: NSObject {
        private let owner: RmbDatePicker
        init(owner: RmbDatePicker) {
            self.owner = owner
        }

        @objc func onValueChange(_ sender: Any?) {
            if let picker = sender as? NSDatePicker {
                owner.selection = picker.dateValue
            }
        }
    }
}

struct RmbDatePicker_Previews: PreviewProvider {
    static var date = Date()
    
    static var previews: some View {
        RmbDatePicker(selection: .constant(date), displayedComponents: .yearMonthDay)
    }
}
