import SwiftUI
import EventKit

struct FormNewReminderView: View {
    @EnvironmentObject var remindersData: RemindersData
    @ObservedObject var userPreferences = UserPreferences.shared
    @Environment(\.colorSchemeContrast) private var colorSchemeContrast
    
    @State var rmbReminder = RmbReminder()
    @State var isShowingInfoOptions = false

    @State var textFieldFocusTrigger = UUID()
    @State var textFieldDynamicHeight: CGFloat = 0

    var body: some View {
        let calendarForSaving = getCalendarForSaving()
        // swiftlint:disable:next redundant_discardable_let
        let _ = CalendarParser.updateShared(with: remindersData.calendars)
        
        Form {
            HStack(alignment: .top) {
                newReminderTextFieldView()
                .padding(.vertical, 8)
                .padding(.horizontal, 8)
                .background(Color.rmbColor(for: .textFieldBackground, and: colorSchemeContrast))
                .cornerRadius(8)
                .textFieldStyle(PlainTextFieldStyle())
                .modifier(ContrastBorderOverlay())
                
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
                        SelectableView(
                            title: rmbLocalized(.newReminderAutoSuggestTodayOption),
                            isSelected: isSelected
                        )
                    }
                    
                    Button(action: { userPreferences.removeParsedDateFromTitle.toggle() }) {
                        let isSelected = userPreferences.removeParsedDateFromTitle
                        SelectableView(
                            title: rmbLocalized(.newReminderRemoveParsedDateOption),
                            isSelected: isSelected
                        )
                    }
                } label: {
                    Circle()
                        .fill(Color(calendarForSaving?.color ?? .white))
                        .frame(width: 24, height: 24)
                }
                .buttonStyle(.plain)
                .frame(width: 24, height: 24)
                .padding(8)
                .help(rmbLocalized(.newReminderCalendarSelectionToSaveHelp))
            }
        }
        .padding(6)
        .onChange(of: rmbReminder.title) { [oldValue = rmbReminder.title] newValue in
            withAnimation(.easeOut(duration: 0.3)) {
                isShowingInfoOptions = !newValue.isEmpty
            }

            // NOTE: When user starts to enter a title we update the suggested date to ensure it is as expected.
            if oldValue.isEmpty {
                rmbReminder.updateSuggestedDate()
            }
        }
        .onAppear {
            rmbReminder = newRmbReminder()
        }
    }

    @ViewBuilder
    func newReminderTextFieldView() -> some View {
        VStack(alignment: .leading) {
            ZStack(alignment: .topTrailing) {
                RmbHighlightedTextField(
                    placeholder: rmbLocalized(.newReminderTextFielPlaceholder),
                    text: $rmbReminder.title,
                    highlightedTexts: rmbReminder.highlightedTexts,
                    textContainerDynamicHeight: $textFieldDynamicHeight,
                    focusTrigger: $textFieldFocusTrigger,
                )
                .onSubmit {
                    createNewReminder()
                }
                .autoComplete(
                    isInitialCharValid: CalendarParser.isInitialCharValid(_:),
                    suggestions: CalendarParser.autoCompleteSuggestions(_:)
                )
                .onChange(of: userPreferences.remindersMenuBarOpeningEvent) { _ in
                    textFieldFocusTrigger = UUID()
                }
                .frame(height: textFieldDynamicHeight)

                Button(action: {
                    createNewReminder()
                }) {
                    Image(systemName: "return")
                        .font(.system(size: 9, weight: .medium))
                        .foregroundColor(.secondary)
                        .frame(width: 20, height: 20)
                        .background(
                            Circle()
                                .fill(Color.gray.opacity(0.15))
                        )
                }
                .buttonStyle(.plain)
                .disabled(rmbReminder.title.isEmpty)
                .padding(.trailing, 4)
                .padding(.top, 4)
                .help("Submit reminder")
            }

            if isShowingInfoOptions {
                NewReminderInfoOptionsView(
                    date: $rmbReminder.date,
                    hasDueDate: $rmbReminder.hasDueDate,
                    hasTime: $rmbReminder.hasTime
                )
            }
        }
    }
    
    private func newRmbReminder() -> RmbReminder {
        var rmbReminder = RmbReminder()
        if userPreferences.autoSuggestToday {
            rmbReminder.setIsAutoSuggestingTodayForCreation()
        }
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
        if let parsedPriorityRange = Range(rmbReminder.textPriorityResult.highlightedText.range, in: title) {
            // Removing priorityText first using the detected Range
            // since there may be different exclamation marks in the title.
            title.replaceSubrange(parsedPriorityRange, with: "")
        }
        if userPreferences.removeParsedDateFromTitle {
            title = title.replacingOccurrences(of: rmbReminder.textDateResult.string, with: "")
        }
        title = title.replacingOccurrences(of: rmbReminder.textCalendarResult.string, with: "")
        
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

struct HiddenMenuIndicator: ViewModifier {
    func body(content: Content) -> some View {
        if #available(macOS 12.0, *) {
            content.menuIndicator(.hidden)
        } else {
            content
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

#Preview {
    FormNewReminderView()
        .environmentObject(RemindersData())
}
