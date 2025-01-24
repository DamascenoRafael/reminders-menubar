import SwiftUI
import EventKit

struct FormNewReminderView: View {
    @EnvironmentObject var remindersData: RemindersData
    @ObservedObject var userPreferences = UserPreferences.shared
    @Environment(\.colorSchemeContrast) private var colorSchemeContrast
    
    @State var rmbReminder = RmbReminder()
    @State var isShowingInfoOptions = false
    
    var body: some View {
        let calendarForSaving = getCalendarForSaving()
        // swiftlint:disable:next redundant_discardable_let
        let _ = CalendarParser.updateShared(with: remindersData.calendars)
        
        Form {
            HStack(alignment: .top) {
                newReminderTextFieldView()
                .padding(.vertical, 8)
                .padding(.horizontal, 8)
                .padding(.leading, 22)
                .background(Color.rmbColor(for: .textFieldBackground, and: colorSchemeContrast))
                .cornerRadius(8)
                .textFieldStyle(PlainTextFieldStyle())
                .modifier(ContrastBorderOverlay())
                .overlay(
                    Image(systemName: "plus.circle.fill")
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                        .foregroundColor(.gray)
                        .padding([.top, .leading], 8)
                )
                
                Menu {
                    ForEach(remindersData.calendars, id: \.calendarIdentifier) { calendar in
                        Button(action: {
                            remindersData.calendarForSaving = calendar
                            let rmbCalendarIdentifier = rmbReminder.textCalendarResult.calendar?.calendarIdentifier
                            if calendar.calendarIdentifier != rmbCalendarIdentifier {
                                // NOTE: Clear textCalendarResult because user overwrote the calendar for saving.
                                rmbReminder.textCalendarResult = CalendarParser.TextCalendarResult()
                            }
                        }) {
                            let isSelected = calendarForSaving?.calendarIdentifier == calendar.calendarIdentifier
                            SelectableView(title: calendar.title, isSelected: isSelected, color: Color(calendar.color))
                        }
                    }
                    
                    Divider()
                    
                    Button(action: {
                        userPreferences.autoSuggestToday.toggle()
                        if rmbReminder.title.isEmpty {
                            rmbReminder = newRmbReminder()
                        }
                    }) {
                        let isSelected = userPreferences.autoSuggestToday
                        SelectableView(title: rmbLocalized(.newReminderAutoSuggestTodayOption),
                                       isSelected: isSelected)
                    }
                    
                    Button(action: { userPreferences.removeParsedDateFromTitle.toggle() }) {
                        let isSelected = userPreferences.removeParsedDateFromTitle
                        SelectableView(title: rmbLocalized(.newReminderRemoveParsedDateOption),
                                       isSelected: isSelected)
                    }
                } label: {
                }
                .menuStyle(BorderlessButtonMenuStyle())
                .frame(width: 14, height: 16)
                .modifier(CenteredMenuPadding())
                .background(Color(calendarForSaving?.color ?? .white))
                .cornerRadius(8)
                .modifier(ContrastBorderOverlay())
                .help(rmbLocalized(.newReminderCalendarSelectionToSaveHelp))
            }
        }
        .padding(10)
        .onChange(of: rmbReminder.title) { [oldValue = rmbReminder.title] newValue in
            withAnimation(.easeOut(duration: 0.3)) {
                isShowingInfoOptions = !newValue.isEmpty
            }

            // NOTE: When user starts to enter a title we re-instantiate RmbReminder to ensure the date is as expected.
            if oldValue.isEmpty {
                rmbReminder = newRmbReminder(withTitle: newValue)
            }
        }
        .onAppear {
            rmbReminder = newRmbReminder()
        }
    }
    
    @ViewBuilder
    func newReminderTextFieldView() -> some View {
        VStack(alignment: .leading) {
            RmbHighlightedTextField(placeholder: rmbLocalized(.newReminderTextFielPlaceholder),
                                    text: $rmbReminder.title,
                                    highlightedTexts: rmbReminder.highlightedTexts,
                                    isInitialCharValidToAutoComplete: CalendarParser.isInitialCharValid(_:),
                                    autoCompleteSuggestions: CalendarParser.autoCompleteSuggestions(_:),
                                    onSubmit: createNewReminder)
            .modifier(FocusOnReceive(userPreferences.$remindersMenuBarOpeningEvent))

            if isShowingInfoOptions {
                NewReminderInfoOptionsView(date: $rmbReminder.date,
                                           priority: $rmbReminder.priority,
                                           hasDueDate: $rmbReminder.hasDueDate,
                                           hasTime: $rmbReminder.hasTime)
            }
        }
    }
    
    private func newRmbReminder(withTitle title: String = "") -> RmbReminder {
        var rmbReminder = RmbReminder(isAutoSuggestingTodayForCreation: userPreferences.autoSuggestToday)
        rmbReminder.title = title
        return rmbReminder
    }
    
    private func getCalendarForSaving() -> EKCalendar? {
        return rmbReminder.textCalendarResult.calendar ?? remindersData.calendarForSaving
    }
    
    private func createNewReminder() {
        let newReminderTitle = finalNewReminderTitle()
        guard !newReminderTitle.isEmpty,
              let calendarForSaving = getCalendarForSaving() else {
            return
        }
        
        rmbReminder.prepareToSave()
        rmbReminder.title = newReminderTitle
        
        RemindersService.shared.createNew(with: rmbReminder, in: calendarForSaving)
        rmbReminder = newRmbReminder()
    }
    
    private func finalNewReminderTitle() -> String {
        var title = rmbReminder.title
        if userPreferences.removeParsedDateFromTitle {
            title = title.replacingOccurrences(of: rmbReminder.textDateResult.string, with: "")
        }
        title = title.replacingOccurrences(of: rmbReminder.textCalendarResult.string, with: "")
        
        let priorityString = rmbReminder.textPriorityResult.string
        if let range = title.range(of: priorityString) {
            title = title.replacingOccurrences(of: priorityString, with: "", range: range)
        }
        return title.trimmingCharacters(in: .whitespaces)
    }
}

struct CenteredMenuPadding: ViewModifier {
    func body(content: Content) -> some View {
        if #available(macOS 14.0, *) {
            content
                .padding(.vertical, 8)
                .padding(.leading, 11)
                .padding(.trailing, 6)
        } else {
            content
                .padding(8)
                .padding(.trailing, 2)
        }
    }
}

struct ContrastBorderOverlay: ViewModifier {
    @Environment(\.colorSchemeContrast) private var colorSchemeContrast
    private var isEnabled: Bool { colorSchemeContrast == .increased }
    
    func body(content: Content) -> some View {
        return content
            .overlay(
                isEnabled
                ? RoundedRectangle(cornerRadius: 8)
                    .strokeBorder(style: StrokeStyle(lineWidth: 1))
                    .foregroundColor(Color.rmbColor(for: .borderContrast, and: colorSchemeContrast))
                : nil
            )
    }
}

struct FormNewReminderView_Previews: PreviewProvider {
    static var reminder: EKReminder {
        let calendar = EKCalendar(for: .reminder, eventStore: .init())
        calendar.color = .systemTeal
        
        let reminder = EKReminder(eventStore: .init())
        reminder.title = "Look for awesome projects on GitHub"
        reminder.isCompleted = false
        reminder.calendar = calendar
        
        let dateComponents = Date().dateComponents(withTime: true)
        reminder.dueDateComponents = dateComponents
        
        return reminder
    }
    
    static var previews: some View {
        Group {
            ForEach(ColorScheme.allCases, id: \.self) { color in
                FormNewReminderView(rmbReminder: RmbReminder(reminder: reminder), isShowingInfoOptions: true)
                    .environmentObject(RemindersData())
                    .colorScheme(color)
                    .previewDisplayName("\(color) mode")
            }
        }
    }
}
