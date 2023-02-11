//
//  NLPDateParser.swift
//  Reminders Menu Bar
//
//  Created by Domiziano Scarcelli on 08/02/23.
//  Copyright © 2023 Rafael Damasceno. All rights reserved.
//

import Foundation
import SwiftyChrono



class NLPDateParser{
    let parser: Chrono
    let userPreferences: UserPreferences
    var isLanguageSupported: Bool {
        Chrono.preferredLanguage != nil
    }
    var isTimeDefined: Bool = false
    var isDateDefined: Bool = false

    init(){
        self.parser = Chrono()
        self.userPreferences = UserPreferences.instance
        //TODO: for now this is set only when the parser is initialized, is has to be changed in order to change every time the language is changes in the application by the user
        Chrono.preferredLanguage = self.getPreferredLanguage(from: rmbCurrentLocale().languageCode)
    }
    
    private func getPreferredLanguage(from languageCode: String?) -> SwiftyChrono.Language? {
        // SwiftyChrono in date 11 Febraury 2023 only supports the listed languages, in case the language is not supported from SwiftyChrono, then the NLP Date parser won't be available
        guard let languageCode = languageCode else {return nil}
        switch languageCode{
        case "en": return .english
        case "fr": return .french
        case "ja": return .japanese
        case "es": return .spanish
        case "zh": return .chinese
        default: return nil
        }
    }
    
    func buildDate(from string: String) -> Date?{
        let parsedResults = parser.parse(text: string, refDate: Date(), opt:[.forwardDate: 1])
        if parsedResults.count == 0 {return nil}
        let startDateInfo: [ComponentUnit: Int] = parsedResults[0].start.knownValues
        let todayComponents = Calendar.current.dateComponents([.year, .month, .day], from: Date())
        var startDateComponents = DateComponents()
        startDateComponents.year = startDateInfo[SwiftyChrono.ComponentUnit.year] ?? todayComponents.year
        startDateComponents.month = startDateInfo[SwiftyChrono.ComponentUnit.month] ?? todayComponents.month
        startDateComponents.day = startDateInfo[SwiftyChrono.ComponentUnit.day] ?? todayComponents.day
        startDateComponents.hour = startDateInfo[SwiftyChrono.ComponentUnit.hour]
        startDateComponents.minute = startDateInfo[SwiftyChrono.ComponentUnit.minute]
        self.isTimeDefined = checkTimeDefined(from: startDateComponents)
        self.isDateDefined = checkDateDefined(from: startDateComponents)
        let userCalendar = Calendar(identifier: .gregorian) //TODO: idk if this has to be changed with user's calendar
        let finalDateTime = userCalendar.date(from: startDateComponents)
        guard let finalDateTime = finalDateTime else {
            return nil
        }
        if finalDateTime < Date() {
            // If the date is in the past, and the time it's not defined, then it's not valid
            if !isTimeDefined {
                return nil
            }
            // Otherwise, we assume that the user is referring to the time for the next day
            startDateComponents.day! += 1
            let finalDateTime = userCalendar.date(from: startDateComponents)
            return finalDateTime
        }
        return finalDateTime
    }
    
    func checkTimeDefined(from date: DateComponents) -> Bool{
        guard let _ = date.minute, let _ = date.hour else {
            return false
        }
        return true
    }
    
    func checkDateDefined(from date: DateComponents) -> Bool{
        guard let _ = date.year, let _ = date.month, let _ = date.day else {
            return false
        }
        return true
    }
    
}


