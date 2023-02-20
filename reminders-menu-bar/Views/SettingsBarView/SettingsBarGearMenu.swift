import SwiftUI
import SwiftyChrono

struct SettingsBarGearMenu: View {
    @EnvironmentObject var remindersData: RemindersData
    
    @State var gearIsHovered = false
    
    @ObservedObject var appUpdateCheckHelper = AppUpdateCheckHelper.instance
    @ObservedObject var keyboardShortcutService = KeyboardShortcutService.instance
    
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
                    UserPreferences.instance.launchAtLoginIsEnabled.toggle()
                }) {
                    let isSelected = UserPreferences.instance.launchAtLoginIsEnabled
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
                UserPreferences.instance.backgroundIsTransparent = false
            }) {
                let isSelected = !UserPreferences.instance.backgroundIsTransparent
                SelectableView(title: rmbLocalized(.appAppearanceMoreOpaqueOptionButton),
                               isSelected: isSelected)
            }
            
            Button(action: {
                UserPreferences.instance.backgroundIsTransparent = true
            }) {
                let isSelected = UserPreferences.instance.backgroundIsTransparent
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
                UserPreferences.instance.showMenuBarTodayCount.toggle()
            }) {
                let isSelected = UserPreferences.instance.showMenuBarTodayCount
                SelectableView(title: rmbLocalized(.showMenuBarTodayCountOptionButton), isSelected: isSelected)
            }
            
            Divider()
            
            ForEach(RmbIcon.allCases, id: \.self) { icon in
                Button(action: {
                    UserPreferences.instance.reminderMenuBarIcon = icon
                    AppDelegate.instance.loadMenuBarIcon()
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
                UserPreferences.instance.preferredLanguage = nil
            }) {
                let isSelected = UserPreferences.instance.preferredLanguage == nil
                SelectableView(title: rmbLocalized(.preferredLanguageSystemOptionButton),
                               isSelected: isSelected)
            }
            
            Divider()
                            
            ForEach(rmbAvailableLocales(), id: \.identifier) { locale in
                let localeIdentifier = locale.identifier
                Button(action: {
                    UserPreferences.instance.preferredLanguage = localeIdentifier
                }) {
                    let isSelected = UserPreferences.instance.preferredLanguage == localeIdentifier
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
