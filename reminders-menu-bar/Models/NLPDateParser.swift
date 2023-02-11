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
        var startDateComponents = DateComponents()
        startDateComponents.year = startDateInfo[SwiftyChrono.ComponentUnit.year]
        startDateComponents.month = startDateInfo[SwiftyChrono.ComponentUnit.month]
        startDateComponents.day = startDateInfo[SwiftyChrono.ComponentUnit.day]
        startDateComponents.hour = startDateInfo[SwiftyChrono.ComponentUnit.hour]
        startDateComponents.minute = startDateInfo[SwiftyChrono.ComponentUnit.minute]
        startDateComponents.second = startDateInfo[SwiftyChrono.ComponentUnit.second]
        let userCalendar = Calendar(identifier: .gregorian) // since the components above (like year 1980) are for Gregorian
        let finalDateTime = userCalendar.date(from: startDateComponents)
        guard let finalDateTime = finalDateTime else {
            return nil
        }
        if finalDateTime < Date() {return nil}
        return finalDateTime
    }
    
}


