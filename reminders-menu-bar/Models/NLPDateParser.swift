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
    
    init(){
        self.parser = Chrono()
        //TODO: Select language by checking the user's selected language
        Chrono.preferredLanguage = .english
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


