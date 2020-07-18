import SwiftUI

struct FormNewReminderView: View {
    var reload: () -> Void
    @State var newReminderTitle: String = ""
    
    var body: some View {
        Form {
            HStack {
                TextField("Type a new reminder and hit enter", text: $newReminderTitle, onCommit: {
                    print("before guard")
                    guard !self.newReminderTitle.isEmpty else { return }
                    print("pass guard")
                    RemindersService.instance.createNew(with: self.newReminderTitle)
                    self.newReminderTitle = ""
                    self.reload()
                })
                    .padding(5)
                    .padding(.horizontal, 10)
                    .padding(.leading, 15)
                    .background(Color.darkTextFieldBackground)
                    .cornerRadius(8)
                    .textFieldStyle(PlainTextFieldStyle())
                    .overlay(
                        Image("plus.circle.filled")
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .foregroundColor(.gray)
                            .padding(.leading, 5)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.textFieldStrock, lineWidth: 0.8)
                    )
                
            }
            .padding(10)
        }
        .background(Color.darkTheme)
    }
}

struct FormNewReminderView_Previews: PreviewProvider {
    static var previews: some View {
        FormNewReminderView(reload: {func reload() {return}})
    }
}
