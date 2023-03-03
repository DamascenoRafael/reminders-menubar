import SwiftUI

struct SettingsBarGearMenu: View {
    @EnvironmentObject var remindersData: RemindersData
    
    @State var gearIsHovered = false
    
    @ObservedObject var appUpdateCheckHelper = AppUpdateCheckHelper.shared
    @ObservedObject var keyboardShortcutService = KeyboardShortcutService.shared
    
    var body: some View {
        Menu {
            VStack {
                if appUpdateCheckHelper.isOutdated {
                    Button(action: {
                        if let url = URL(string: GithubConstants.latestReleasePage) {
                            NSWorkspace.shared.open(url)
                        }
                    }) {
                        Image(systemName: "exclamationmark.circle")
                        Text(rmbLocalized(.updateAvailableNoticeButton))
                    }
                    
                    Divider()
                }
                
                Button(action: {
                    UserPreferences.shared.launchAtLoginIsEnabled.toggle()
                }) {
                    let isSelected = UserPreferences.shared.launchAtLoginIsEnabled
                    SelectableView(title: rmbLocalized(.launchAtLoginOptionButton),
                                   isSelected: isSelected,
                                   withPadding: false)
                }
                
                visualCustomizationOptions()
                
                Button {
                    KeyboardShortcutView.showWindow()
                } label: {
                    let activeShortcut = keyboardShortcutService.activeShortcut(for: .openRemindersMenuBar)
                    let activeShortcutText = Text("     \(activeShortcut)").foregroundColor(.gray)
                    Text(rmbLocalized(.keyboardShortcutOptionButton)) + activeShortcutText
                }
                
                Divider()
                
                Button(action: {
                    remindersData.update()
                }) {
                    Text(rmbLocalized(.reloadRemindersDataButton))
                }
                
                Divider()
                
                Button(action: {
                    AboutView.showWindow()
                }) {
                    Text(rmbLocalized(.appAboutButton))
                }
                
                Button(action: {
                    NSApplication.shared.terminate(self)
                }) {
                    Text(rmbLocalized(.appQuitButton))
                }
            }
        } label: {
            Image(systemName: appUpdateCheckHelper.isOutdated ? "exclamationmark.circle" : "gear")
        }
        .menuStyle(BorderlessButtonMenuStyle())
        .frame(width: 32, height: 16)
        .padding(3)
        .background(gearIsHovered ? Color("buttonHover") : nil)
        .cornerRadius(4)
        .onHover { isHovered in
            gearIsHovered = isHovered
        }
        .help(rmbLocalized(.settingsButtonHelp))
    }
    
    @ViewBuilder
    func visualCustomizationOptions() -> some View {
        Divider()
        
        appAppearanceMenu()
        
        menuBarSettingsMenu()
        
        preferredLanguageMenu()
        
        Divider()
    }
    
    func appAppearanceMenu() -> some View {
        Menu {
            Button(action: {
                UserPreferences.shared.backgroundIsTransparent = false
            }) {
                let isSelected = !UserPreferences.shared.backgroundIsTransparent
                SelectableView(title: rmbLocalized(.appAppearanceMoreOpaqueOptionButton),
                               isSelected: isSelected)
            }
            
            Button(action: {
                UserPreferences.shared.backgroundIsTransparent = true
            }) {
                let isSelected = UserPreferences.shared.backgroundIsTransparent
                SelectableView(title: rmbLocalized(.appAppearanceMoreTransparentOptionButton),
                               isSelected: isSelected)
            }
        } label: {
            Text(rmbLocalized(.appAppearanceMenu))
        }
    }
    
    func menuBarSettingsMenu() -> some View {
        Menu {
            Button(action: {
                UserPreferences.shared.showMenuBarTodayCount.toggle()
            }) {
                let isSelected = UserPreferences.shared.showMenuBarTodayCount
                SelectableView(title: rmbLocalized(.showMenuBarTodayCountOptionButton), isSelected: isSelected)
            }
            
            Divider()
            
            ForEach(RmbIcon.allCases, id: \.self) { icon in
                Button(action: {
                    UserPreferences.shared.reminderMenuBarIcon = icon
                    AppDelegate.shared.loadMenuBarIcon()
                }) {
                    Image(nsImage: icon.image)
                    Text(icon.name)
                }
            }
        } label: {
            Text(rmbLocalized(.menuBarSettingsMenu))
        }
    }
    
    func preferredLanguageMenu() -> some View {
        Menu {
            Button(action: {
                UserPreferences.shared.preferredLanguage = nil
            }) {
                let isSelected = UserPreferences.shared.preferredLanguage == nil
                SelectableView(title: rmbLocalized(.preferredLanguageSystemOptionButton),
                               isSelected: isSelected)
            }
            
            Divider()
                            
            ForEach(rmbAvailableLocales(), id: \.identifier) { locale in
                let localeIdentifier = locale.identifier
                Button(action: {
                    UserPreferences.shared.preferredLanguage = localeIdentifier
                }) {
                    let isSelected = UserPreferences.shared.preferredLanguage == localeIdentifier
                    SelectableView(title: locale.name, isSelected: isSelected)
                }
            }
        } label: {
            Text(rmbLocalized(.preferredLanguageMenu))
        }
    }
}

struct SettingsBarGearMenu_Previews: PreviewProvider {
    static var previews: some View {
        SettingsBarGearMenu()
    }
}
