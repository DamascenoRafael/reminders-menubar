import SwiftUI

struct SettingsBarGearMenu: View {
    @EnvironmentObject var remindersData: RemindersData
    @ObservedObject var userPreferences = UserPreferences.shared
    @ObservedObject var firebase = FirebaseManager.shared
    @Environment(\.colorSchemeContrast) private var colorSchemeContrast
    
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
                    userPreferences.launchAtLoginIsEnabled.toggle()
                }) {
                    let isSelected = userPreferences.launchAtLoginIsEnabled
                    SelectableView(
                        title: rmbLocalized(.launchAtLoginOptionButton),
                        isSelected: isSelected,
                        withPadding: false
                    )
                }
                
                visualCustomizationOptions()
                
                Button {
                    KeyboardShortcutView.showWindow()
                } label: {
                    let activeShortcut = keyboardShortcutService.activeShortcut(for: .openRemindersMenuBar)
                    let activeShortcutText = Text(verbatim: "     \(activeShortcut)").foregroundColor(.gray)
                    Text(rmbLocalized(.keyboardShortcutOptionButton)) + activeShortcutText
                }
                
                Divider()
                
                Button(action: {
                    Task {
                        await remindersData.update()
                    }
                }) {
                    Text(rmbLocalized(.reloadRemindersDataButton))
                }
                
                Divider()
                
                Button(action: {
                    AboutView.showWindow()
                }) {
                    Text(rmbLocalized(.appAboutButton))
                }

                Divider()

                Menu {
                    // Signed-in status line
                    if FirebaseManager.isAvailable {
                        if firebase.isSignedIn {
                            let name = firebase.displayName ?? firebase.email ?? firebase.uid ?? "Unknown"
                            Text("Signed in as: \(name)")
                        } else {
                            Text("Not signed in")
                        }
                        Divider()
                    }
                    Button(action: {
                        WebSignInView.showWindow()
                    }) {
                        Text("Sign in to BOB (Google)…")
                    }
                    if FirebaseManager.isAvailable && firebase.isSignedIn {
                        Button(action: {
                            GoogleSignInService.shared.signOut()
                            FirebaseManager.shared.refreshUser()
                        }) {
                            Text("Sign out")
                        }
                    }
                    Button(action: {
                        Task {
                            if FirebaseManager.isAvailable && FirebaseManager.shared.isSignedIn {
                                await BobFirestoreSyncService.shared.syncFromBob()
                            } else {
                                await BobSyncService.shared.syncFromBob()
                            }
                        }
                    }) {
                        Text("Run Sync from BOB → Reminders")
                    }
                    Button(action: {
                        BobSyncSettingsView.showWindow()
                    }) {
                        Text("BOB Sync Settings…")
                    }
                } label: {
                    Text("BOB Sync")
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
        .background(gearIsHovered ? Color.rmbColor(for: .buttonHover, and: colorSchemeContrast) : nil)
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
        
        menuBarIconMenu()
        
        menuBarCounterMenu()
        
        preferredLanguageMenu()
        
        Divider()
    }
    
    func appAppearanceMenu() -> some View {
        Menu {
            ForEach(RmbColorScheme.allCases, id: \.rawValue) { colorScheme in
                Button(action: { userPreferences.rmbColorScheme = colorScheme }) {
                    let isSelected = colorScheme == userPreferences.rmbColorScheme
                    SelectableView(title: colorScheme.title, isSelected: isSelected)
                }
            }
            
            Divider()
            
            let isIncreasedContrastEnabled = colorSchemeContrast == .increased
            let isTransparencyEnabled = userPreferences.backgroundIsTransparent && !isIncreasedContrastEnabled
            
            Button(action: {
                userPreferences.backgroundIsTransparent = false
            }) {
                let isSelected = !isTransparencyEnabled
                SelectableView(
                    title: rmbLocalized(.appAppearanceMoreOpaqueOptionButton),
                    isSelected: isSelected
                )
            }
            .disabled(isIncreasedContrastEnabled)
            
            Button(action: {
                userPreferences.backgroundIsTransparent = true
            }) {
                let isSelected = isTransparencyEnabled
                SelectableView(
                    title: rmbLocalized(.appAppearanceMoreTransparentOptionButton),
                    isSelected: isSelected
                )
            }
            .disabled(isIncreasedContrastEnabled)
        } label: {
            Text(rmbLocalized(.appAppearanceMenu))
        }
    }
    
    func menuBarIconMenu() -> some View {
        Menu {
            ForEach(RmbIcon.allCases, id: \.self) { icon in
                Button(action: {
                    userPreferences.reminderMenuBarIcon = icon
                    AppDelegate.shared.loadMenuBarIcon()
                }) {
                    Image(nsImage: icon.image)
                    Text(icon.name)
                }
            }
        } label: {
            Text(rmbLocalized(.menuBarIconSettingsMenu))
        }
    }
    
    func menuBarCounterMenu() -> some View {
        Menu {
            ForEach(RmbMenuBarCounterType.allCases, id: \.rawValue) { counterType in
                Button(action: { userPreferences.menuBarCounterType = counterType }) {
                    let isSelected = counterType == userPreferences.menuBarCounterType
                    SelectableView(title: counterType.title, isSelected: isSelected)
                }
            }
            
            Divider()
            
            Button(action: {
                userPreferences.filterMenuBarCountByCalendar.toggle()
            }) {
                SelectableView(
                    title: rmbLocalized(.filterMenuBarCountByCalendarOptionButton),
                    isSelected: userPreferences.filterMenuBarCountByCalendar
                )
            }
        } label: {
            Text(rmbLocalized(.menuBarCounterSettingsMenu))
        }
    }
    
    func preferredLanguageMenu() -> some View {
        Menu {
            Button(action: {
                userPreferences.preferredLanguage = nil
            }) {
                let isSelected = userPreferences.preferredLanguage == nil
                SelectableView(
                    title: rmbLocalized(.preferredLanguageSystemOptionButton),
                    isSelected: isSelected
                )
            }
            
            Divider()
                            
            ForEach(rmbAvailableLocales(), id: \.identifier) { locale in
                let localeIdentifier = locale.identifier
                Button(action: {
                    userPreferences.preferredLanguage = localeIdentifier
                }) {
                    let isSelected = userPreferences.preferredLanguage == localeIdentifier
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
