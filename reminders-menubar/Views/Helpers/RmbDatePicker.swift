import SwiftUI

struct RmbDatePicker: NSViewRepresentable {
    @Binding var selection: Date
    var displayedComponents: NSDatePicker.ElementFlags
    private var font: NSFont?
    
    init(selection: Binding<Date>, components: DatePickerComponents) {
        _selection = selection
        self.displayedComponents = components.displayedComponents
    }

    enum DatePickerComponents {
        case date
        case time
        
        var displayedComponents: NSDatePicker.ElementFlags {
            switch self {
            case .date:
                return .yearMonthDay
            case .time:
                return .hourMinute
            }
        }
    }
    
    func makeNSView(context: Context) -> NSDatePicker {
        let picker = NSDatePicker()
        picker.font = font ?? picker.font
        picker.isBordered = false
        picker.datePickerStyle = .textField
        picker.presentsCalendarOverlay = true
        picker.datePickerElements = displayedComponents
        picker.action = #selector(Coordinator.onValueChange(_:))
        picker.target = context.coordinator
        picker.locale = rmbCurrentLocale()
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

extension RmbDatePicker {
    func font(_ font: NSFont?) -> RmbDatePicker {
        var view = self
        view.font = font
        return view
    }
}

struct RmbDatePicker_Previews: PreviewProvider {
    static var date = Date()
    
    static var previews: some View {
        RmbDatePicker(selection: .constant(date), components: .date)
    }
}
