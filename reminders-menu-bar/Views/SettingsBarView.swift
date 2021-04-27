import SwiftUI
import EventKit

struct SettingsBarView: View {
    @EnvironmentObject var remindersData: RemindersData
    @ObservedObject var userPreferences = UserPreferences.instance
    
    @State var filterIsHovered = false
    @State var toggleIsHovered = false
    @State var settingsIsHovered = false
    
    @ObservedObject var appUpdateCheckHelper = AppUpdateCheckHelper.instance
    
    var body: some View {
        HStack {
            Menu {
                Button(action: {
                    UserPreferences.instance.showUpcomingReminders.toggle()
                }) {
                    let isSelected = UserPreferences.instance.showUpcomingReminders
                    SelectableView(title: "Upcoming reminders", isSelected: isSelected)
                }
                
                VStack {
                    Divider()
                }
                
                ForEach(remindersData.calendars, id: \.calendarIdentifier) { calendar in
                    let calendarIdentifier = calendar.calendarIdentifier
                    Button(action: {
                        let index = userPreferences.calendarIdentifiersFilter.firstIndex(of: calendarIdentifier)
                        if let index = index {
                            userPreferences.calendarIdentifiersFilter.remove(at: index)
                        } else {
                            userPreferences.calendarIdentifiersFilter.append(calendarIdentifier)
                        }
                    }) {
                        let isSelected = userPreferences.calendarIdentifiersFilter.contains(calendarIdentifier)
                        SelectableView(title: calendar.title, isSelected: isSelected, color: Color(calendar.color))
                    }
                }
            } label: {
                Image(systemName: "line.horizontal.3.decrease.circle")
            }
            .menuStyle(BorderlessButtonMenuStyle())
            .frame(width: 32, height: 16)
            .padding(3)
            .background(filterIsHovered ? Color("buttonHover") : nil)
            .cornerRadius(4)
            .onHover { isHovered in
                filterIsHovered = isHovered
            }
            .help("Filter which reminders to show")
            
            Spacer()
            
            Button(action: {
                userPreferences.showUncompletedOnly.toggle()
            }) {
                Image(systemName: userPreferences.showUncompletedOnly ? "circle" : "largecircle.fill.circle")
                    .padding(4)
                    .padding(.horizontal, 4)
            }
            .buttonStyle(BorderlessButtonStyle())
            .background(toggleIsHovered ? Color("buttonHover") : nil)
            .cornerRadius(4)
            .onHover { isHovered in
                toggleIsHovered = isHovered
            }
            .help("Toggle between showing all reminders or only uncompleted ones")
            
            Spacer()
            
            Menu {
                if appUpdateCheckHelper.isOutdated {
                    Button(action: {
                        if let url = URL(string: GithubConstants.latestReleasePage) {
                            NSWorkspace.shared.open(url)
                        }
                    }) {
                        Image(systemName: "exclamationmark.circle")
                        Text("Update avaiable")
                    }
                    
                    VStack {
                        Divider()
                    }
                }
                
                Button(action: {
                    UserPreferences.instance.launchAtLoginIsEnabled.toggle()
                }) {
                    let isSelected = UserPreferences.instance.launchAtLoginIsEnabled
                    SelectableView(title: "Launch at login", isSelected: isSelected, withPadding: false)
                }
                
                VStack {
                    Divider()
                }
                
                Menu {
                    Button(action: {
                        UserPreferences.instance.backgroundIsTransparent = false
                    }) {
                        let isSelected = !UserPreferences.instance.backgroundIsTransparent
                        SelectableView(title: "More opaque", isSelected: isSelected)
                    }
                    
                    Button(action: {
                        UserPreferences.instance.backgroundIsTransparent = true
                    }) {
                        let isSelected = UserPreferences.instance.backgroundIsTransparent
                        SelectableView(title: "More transparent", isSelected: isSelected)
                    }
                } label: {
                    Text("Appearance")
                }
                
                VStack {
                    Divider()
                }
                
                Button(action: {
                    remindersData.update()
                }) {
                    Text("Reload data")
                }
                
                VStack {
                    Divider()
                }
                
                Button(action: {
                    AboutView.showWindow()
                }) {
                    Text("About")
                }
                
                Button(action: {
                    NSApplication.shared.terminate(self)
                }) {
                    Text("Quit")
                }
            } label: {
                Image(systemName: appUpdateCheckHelper.isOutdated ? "exclamationmark.circle" : "gear")
            }
            .menuStyle(BorderlessButtonMenuStyle())
            .frame(width: 32, height: 16)
            .padding(3)
            .background(settingsIsHovered ? Color("buttonHover") : nil)
            .cornerRadius(4)
            .onHover { isHovered in
                settingsIsHovered = isHovered
            }
            .help("Settings")
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 12)
        .padding(.bottom, 10)
        .padding(.horizontal, 10)
    }
}

struct SettingsBarView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            ForEach(ColorScheme.allCases, id: \.self) { color in
                SettingsBarView()
                    .environmentObject(RemindersData())
                    .colorScheme(color)
                    .previewDisplayName("\(color) mode")
            }
        }
    }
}
