import SwiftUI

struct SettingsBarGearMenu: View {
    @EnvironmentObject var remindersData: RemindersData
    @ObservedObject var userPreferences = UserPreferences.shared
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

                apiServerOptions()

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

    @ViewBuilder
    func apiServerOptions() -> some View {
        Button(action: {
            userPreferences.apiServerEnabled.toggle()
        }) {
            let isSelected = userPreferences.apiServerEnabled
            SelectableView(
                title: rmbLocalized(.apiServerOptionButton),
                isSelected: isSelected,
                withPadding: false
            )
        }

        if userPreferences.apiServerEnabled {
            apiServerPortOptions()
        }
    }

    @ViewBuilder
    func apiServerPortOptions() -> some View {
        Menu {
            ForEach([7777, 3000, 8000, 8080, 9000], id: \.self) { port in
                Button(action: {
                    userPreferences.apiServerPort = port
                }) {
                    let isSelected = userPreferences.apiServerPort == port
                    SelectableView(
                        title: rmbLocalized(.apiPortOption, arguments: String(port)),
                        isSelected: isSelected
                    )
                }
            }

            Divider()

            Button(action: {
                showCustomPortDialog()
            }) {
                Text(rmbLocalized(.apiCustomPortButton))
            }

            Divider()

            Button(action: {
                if let url = URL(string: "http://localhost:\(userPreferences.apiServerPort)") {
                    NSWorkspace.shared.open(url)
                }
            }) {
                Text(rmbLocalized(.apiOpenInBrowserButton))
            }
        } label: {
            Text(rmbLocalized(.apiPortMenuTitle, arguments: String(userPreferences.apiServerPort)))
        }
    }

    private func showCustomPortDialog() {
        let alert = NSAlert()
        alert.messageText = rmbLocalized(.apiCustomPortAlertTitle)
        alert.informativeText = rmbLocalized(.apiCustomPortAlertMessage)

        let textField = NSTextField(frame: NSRect(x: 0, y: 0, width: 200, height: 24))
        textField.stringValue = String(userPreferences.apiServerPort)
        alert.accessoryView = textField

        alert.addButton(withTitle: rmbLocalized(.okButton))
        alert.addButton(withTitle: rmbLocalized(.cancelButton))

        let response = alert.runModal()
        if response == .alertFirstButtonReturn {
            if let port = Int(textField.stringValue), port >= 1024 && port <= 65535 {
                userPreferences.apiServerPort = port
            }
        }
    }
}

struct SettingsBarGearMenu_Previews: PreviewProvider {
    static var previews: some View {
        SettingsBarGearMenu()
    }
}
