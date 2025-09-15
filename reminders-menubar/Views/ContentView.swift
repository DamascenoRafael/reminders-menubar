import SwiftUI
import EventKit

struct ContentView: View {
    @EnvironmentObject var remindersData: RemindersData
    @ObservedObject var userPreferences = UserPreferences.shared
    @ObservedObject var firebase = FirebaseManager.shared
    @Environment(\.colorSchemeContrast) private var colorSchemeContrast
    
    var body: some View {
        VStack(spacing: 0) {
            FormNewReminderView()
            
            if userPreferences.atLeastOneFilterIsSelected {
                List {
                    if userPreferences.showUpcomingReminders {
                        Section(header: UpcomingRemindersTitle()) {
                            UpcomingRemindersContent()
                        }
                        .modifier(ListSectionSpacing())
                        .modifier(ListRowSeparatorHidden())
                    }
                    ForEach(remindersData.filteredReminderLists) { reminderList in
                        Section(header: CalendarTitle(calendar: reminderList.calendar)) {
                            let uncompletedIsEmpty = reminderList.reminders.uncompleted.isEmpty
                            let completedIsEmpty = reminderList.reminders.completed.isEmpty
                            let calendarIsEmpty = uncompletedIsEmpty && completedIsEmpty
                            let isShowingCompleted = !userPreferences.showUncompletedOnly
                            let viewIsEmpty = isShowingCompleted ? calendarIsEmpty : uncompletedIsEmpty
                            if viewIsEmpty {
                                NoReminderItemsView(emptyList: calendarIsEmpty ? .noReminders : .allItemsCompleted)
                            }
                            ForEach(reminderList.reminders.uncompleted) { reminderItem in
                                ReminderItemView(reminderItem: reminderItem, isShowingCompleted: isShowingCompleted)
                            }
                            if isShowingCompleted {
                                ForEach(reminderList.reminders.completed) { reminderItem in
                                    ReminderItemView(reminderItem: reminderItem, isShowingCompleted: isShowingCompleted)
                                }
                            }
                        }
                        .modifier(ListSectionSpacing())
                        .modifier(ListRowSeparatorHidden())
                    }
                }
                .listStyle(.plain)
                .animation(.default, value: remindersData.filteredReminderLists)
            } else {
                VStack(spacing: 4) {
                    Text(rmbLocalized(.emptyListNoRemindersFilterTitle))
                        .multilineTextAlignment(.center)
                    Text(rmbLocalized(.emptyListNoRemindersFilterMessage))
                        .multilineTextAlignment(.center)
                }
                .frame(maxHeight: .infinity)
            }
            // BOB sign-in status and clear call-to-action
            if FirebaseManager.isAvailable {
                if firebase.isSignedIn {
                    HStack {
                        let name = firebase.displayName ?? firebase.email ?? firebase.uid
                        let shown = name ?? "Unknown"
                        Text("Signed in as: " + shown)
                            .font(.footnote)
                            .foregroundColor(.secondary)
                        Spacer()
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                } else {
                    HStack(spacing: 12) {
                        Text("Not signed in")
                            .foregroundColor(.secondary)
                        Button("Sign In") {
                            Task {
                                do {
                                    try await GoogleSignInService.shared.signIn()
                                    FirebaseManager.shared.refreshUser()
                                    LogService.shared.log(.info, .auth, "Signed in with Google (native)")
                                } catch {
                                    LogService.shared.log(.error, .auth, "Native sign-in failed: \(error.localizedDescription)")
                                }
                            }
                        }
                        .buttonStyle(.borderedProminent)
                        Spacer()
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                }
            }

            SettingsBarView()
        }
        .background(Color.rmbColor(for: .backgroundTheme, and: colorSchemeContrast).padding(-80))
        .preferredColorScheme(userPreferences.rmbColorScheme.colorScheme)
        // Auto-sync from BOB when user signs in natively
        .onChange(of: firebase.isSignedIn) { _, newValue in
            if newValue {
                Task { await BobFirestoreSyncService.shared.syncFromBob() }
            }
        }
        .onAppear {
            if FirebaseManager.isAvailable && firebase.isSignedIn {
                Task { await BobFirestoreSyncService.shared.syncFromBob() }
            }
        }
    }
}

struct ListSectionSpacing: ViewModifier {
    func body(content: Content) -> some View {
        return content
            .listRowInsets(EdgeInsets(top: 0, leading: 0, bottom: 8, trailing: 0))
            .padding(.horizontal, 8)
    }
}

struct ListRowSeparatorHidden: ViewModifier {
    func body(content: Content) -> some View {
        if #available(macOS 14.0, *) {
            content
                .listRowSeparator(.hidden)
        } else {
            content
        }
    }
}

 struct ContentView_Previews: PreviewProvider {
     static var previews: some View {
         ContentView().environmentObject(RemindersData())
     }
 }
