import SwiftUI
import EventKit

struct SettingsBarView: View {
    @EnvironmentObject var remindersData: RemindersData
    
    @State var filterIsHovered = false
    @State var toggleIsHovered = false
    @State var settingsIsHovered = false
    
    var body: some View {
        HStack {
            Menu {
                ForEach(remindersData.calendars, id: \.calendarIdentifier) { calendar in
                    Button(action: {
                        let index = self.remindersData.calendarIdentifiersFilter.firstIndex(of: calendar.calendarIdentifier)
                        if let index = index {
                            self.remindersData.calendarIdentifiersFilter.remove(at: index)
                        } else {
                            self.remindersData.calendarIdentifiersFilter.append(calendar.calendarIdentifier)
                        }
                    }) {
                        HStack {
                            let isSelected = self.remindersData.calendarIdentifiersFilter.contains(calendar.calendarIdentifier)
                            if isSelected {
                                Image(systemName: "checkmark")
                            }
                            let paddingText = isSelected ? "" : "      "
                            Text(paddingText + calendar.title)
                                .foregroundColor(Color(calendar.color))
                        }
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
                self.filterIsHovered = isHovered
            }
            
            Spacer()
            
            Button(action: {
                self.remindersData.showUncompletedOnly.toggle()
            }) {
                Image(systemName: self.remindersData.showUncompletedOnly ? "circle" : "largecircle.fill.circle")
            }
            .buttonStyle(BorderlessButtonStyle())
            .padding(4)
            .padding(.horizontal, 4)
            .background(toggleIsHovered ? Color("buttonHover") : nil)
            .cornerRadius(4)
            .onHover { isHovered in
                self.toggleIsHovered = isHovered
            }
            
            Spacer()
            
            Menu {
                Button(action: {
                    self.remindersData.loadCalendars()
                }) {
                    Text("Reload data")
                }
                
                VStack {
                    Divider()
                }
                
                Button(action: {
                    NSApplication.shared.terminate(self)
                }) {
                    Text("Quit")
                }
            } label: {
                Image(systemName: "gear")
            }
            .menuStyle(BorderlessButtonMenuStyle())
            .frame(width: 32, height: 16)
            .padding(3)
            .background(settingsIsHovered ? Color("buttonHover") : nil)
            .cornerRadius(4)
            .onHover { isHovered in
                self.settingsIsHovered = isHovered
            }
            
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 12)
        .padding(.bottom, 10)
        .padding(.horizontal, 10)
        .background(Color("backgroundTheme"))
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
