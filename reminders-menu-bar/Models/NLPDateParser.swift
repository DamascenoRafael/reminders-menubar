import Foundation
import SwiftyChrono

class NLPDateParser {
    let parser: Chrono
    let userPreferences: UserPreferences
    var isLanguageSupported: Bool {
        Chrono.preferredLanguage != nil
    }
    var isTimeDefined = false
    var isDateDefined = false
    var userCalendar: Calendar

    init() {
        self.parser = Chrono()
        self.userPreferences = UserPreferences.instance
        self.userCalendar = Calendar(identifier: .gregorian)
        Chrono.preferredLanguage = NLPDateParser.getPreferredLanguage(from: rmbCurrentLocale().languageCode)
    }
    
    static func getPreferredLanguage(from languageCode: String?) -> SwiftyChrono.Language? {
        // SwiftyChrono in date 11 Febraury 2023 only supports the listed languages, in case the language is
        // not supported from SwiftyChrono, then the NLP Date parser won't be available
        guard let languageCode else { return nil }
        switch languageCode {
        case "en":
            return .english
        case "fr":
            return .french
        case "ja":
            return .japanese
        case "es":
            return .spanish
        case "zh":
            return .chinese
        default:
            return nil
        }
    }
    
    func buildDate(from string: String) -> (Date, String)? {
        let parsedResults = parser.parse(text: string, refDate: Date(), opt: [.forwardDate: 1])
        if parsedResults.isEmpty {return nil}
        
        var startDateInfo: [ComponentUnit: Int] = parsedResults[0].start.knownValues
        if startDateInfo.isEmpty {
            startDateInfo = parsedResults[0].start.impliedValues
        }
        let dateRelatedText: String = parsedResults[0].text
        let todayComponents = userCalendar.dateComponents([.year, .month, .day, .hour, .minute], from: Date())
        var startDateComponents = DateComponents()
        startDateComponents.year = startDateInfo[SwiftyChrono.ComponentUnit.year]
        startDateComponents.month = startDateInfo[SwiftyChrono.ComponentUnit.month]
        startDateComponents.day = startDateInfo[SwiftyChrono.ComponentUnit.day]
        startDateComponents.hour = startDateInfo[SwiftyChrono.ComponentUnit.hour]
        startDateComponents.minute = startDateInfo[SwiftyChrono.ComponentUnit.minute]
        
        isDateDefined = checkDateDefined(from: startDateComponents)
        isTimeDefined = checkTimeDefined(from: startDateComponents)
        
        // If only the time is defined, and it's a past time, then we assume the user
        // is referring to the time for the next day, otherwise we assume it's for the current day
        if !isDateDefined && isTimeDefined {
            guard let isPastTime = checkPastTime(from: startDateComponents) else { return nil }
            if isPastTime {
                startDateComponents.year = todayComponents.year
                startDateComponents.month = todayComponents.month
                startDateComponents.day = todayComponents.day! + 1
                let finalDateTime = userCalendar.date(from: startDateComponents)
                guard let finalDateTime else { return nil }
                isDateDefined = true
                return (finalDateTime, dateRelatedText)
            } else {
                startDateComponents.year = todayComponents.year
                startDateComponents.month = todayComponents.month
                startDateComponents.day = todayComponents.day
                let finalDateTime = userCalendar.date(from: startDateComponents)
                guard let finalDateTime else { return nil }
                isDateDefined = true
                return (finalDateTime, dateRelatedText)
            }
        }
        
        let finalDateTime = userCalendar.date(from: startDateComponents)
        guard var finalDateTime else {return nil}

        // If the user insert "Today" without time, then just return it
        if checkIfToday(from: startDateComponents) && !isTimeDefined { return (finalDateTime, dateRelatedText) }
        
        // If the date is in the past, then it's not valid
        if isDateDefined && startDateComponents.year == nil {
            startDateComponents.year = todayComponents.year
            finalDateTime = userCalendar.date(from: startDateComponents)!
        }
        guard let isPastDay = checkIfPastDay(from: startDateComponents) else { return nil }
        if isPastDay { return nil }
        return (finalDateTime, dateRelatedText)
    }
    
    
    private func checkIfToday(from date: DateComponents) -> Bool {
        let todayComponents = Calendar.current.dateComponents([.year, .month, .day], from: Date())
        return date.day == todayComponents.day
            && date.month == todayComponents.month
            && date.year == todayComponents.year
    }
    
    private func checkIfPastDay(from date: DateComponents) -> Bool? {
        if date.year == nil || date.month == nil || date.day == nil { return nil }
        return Calendar.current.date(from: date)! < Date()
    }
    
    private func checkPastTime(from date: DateComponents) -> Bool? {
        let todayComponents = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: Date())
        if date.hour == nil || date.minute == nil { return nil }
        let isPastHour = date.hour! < todayComponents.hour!
        let isPastMinute = date.hour! == todayComponents.hour!
            && date.minute! < todayComponents.minute!
        return isPastHour || isPastMinute
    }
    
    private func checkTimeDefined(from date: DateComponents) -> Bool {
        return date.minute != nil && date.hour != nil
    }
    
    private func checkDateDefined(from date: DateComponents) -> Bool {
        return date.month != nil && date.day != nil
    }
}
