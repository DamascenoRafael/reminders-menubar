import SwiftUI

struct SettingsBarGearMenu: View {
    @EnvironmentObject var remindersData: RemindersData
    
    @State var gearIsHovered = false
    
    @ObservedObject var appUpdateCheckHelper = AppUpdateCheckHelper.instance
    
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
            
            Divider()
            
            Button(action: {
                UserPreferences.instance.showMenuBarTodayCount.toggle()
            }) {
                let isSelected = UserPreferences.instance.showMenuBarTodayCount
                SelectableView(title: rmbLocalized(.showMenuBarTodayCountOptionButton), isSelected: isSelected)
            }
        } label: {
            Text(rmbLocalized(.appAppearanceMenu))
        }
        
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
        
        Divider()
    }
}

struct SettingsBarGearMenu_Previews: PreviewProvider {
    static var previews: some View {
        SettingsBarGearMenu()
    }
}
