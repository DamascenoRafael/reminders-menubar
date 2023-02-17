import Foundation
import SwiftyChrono

class NLPDateParser {
    let parser: Chrono
    let userPreferences: UserPreferences
    var isLanguageSupported: Bool {
        Chrono.preferredLanguage != nil
    }
    var isTimeDefined: Bool {
        return parsedDateComponents.minute != nil && parsedDateComponents.hour != nil
    }
    var isDateDefined: Bool {
        let isDayMonth = parsedDateComponents.day != nil && parsedDateComponents.month != nil
        if isDayMonth && parsedDateComponents.year == nil {
            parsedDateComponents.year = isPastDay ? todayDateComponents.year! + 1 : todayDateComponents.year
        }
        return isDayMonth
    }
    var userCalendar: Calendar
    
    var isToday: Bool {
        return parsedDateComponents.day == todayDateComponents.day
            && parsedDateComponents.month == todayDateComponents.month
            && parsedDateComponents.year == todayDateComponents.year
    }

    var isPastDay: Bool {
        if parsedDateComponents.month! < todayDateComponents.month! {
            if parsedDateComponents.day! < todayDateComponents.day! {
                return true
            }
        }
        return false
    }
    
    var isPastTime: Bool {
        let isPastHour = parsedDateComponents.hour! < todayDateComponents.hour!
        let isPastMinute = parsedDateComponents.hour! == todayDateComponents.hour!
            && parsedDateComponents.minute! < todayDateComponents.minute!
        return isPastHour || isPastMinute
    }
    
    var dateRelatedText: String
    
    let todayDateComponents: DateComponents
    
    var parsedDateComponents: DateComponents {
        didSet {
            
            if !isDateDefined && isTimeDefined {
                parsedDateComponents.day = todayDateComponents.day
                parsedDateComponents.month = todayDateComponents.month
                parsedDateComponents.year = todayDateComponents.year
            }
            
            if isDateDefined && isTimeDefined && isToday {
                if !isPastTime { return }
                parsedDateComponents.day! += 1
            }
        }
    }

    init() {
        self.parser = Chrono()
        self.userPreferences = UserPreferences.instance
        self.userCalendar = Calendar(identifier: .gregorian)
        self.todayDateComponents = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: Date())
        self.parsedDateComponents = DateComponents()
        self.dateRelatedText = ""
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
    
    func buildDate(from string: String) -> Date? {
        clear()
        let parsedResults = parser.parse(text: string, refDate: Date(), opt: [.forwardDate: 1])
        if parsedResults.isEmpty {return nil}
        
        var startDateInfo: [ComponentUnit: Int] = parsedResults[0].start.knownValues
        if startDateInfo.isEmpty {
            startDateInfo = parsedResults[0].start.impliedValues
        }
        dateRelatedText = parsedResults[0].text
        
        parsedDateComponents.year = startDateInfo[SwiftyChrono.ComponentUnit.year]
        parsedDateComponents.month = startDateInfo[SwiftyChrono.ComponentUnit.month]
        parsedDateComponents.day = startDateInfo[SwiftyChrono.ComponentUnit.day]
        parsedDateComponents.hour = startDateInfo[SwiftyChrono.ComponentUnit.hour]
        parsedDateComponents.minute = startDateInfo[SwiftyChrono.ComponentUnit.minute]
        
        guard let finalDate = userCalendar.date(from: parsedDateComponents) else { return nil }
        if finalDate < Date() && !isToday { return nil}
        
        return finalDate
    }
    
    private func clear() {
        self.parsedDateComponents = DateComponents()
        self.dateRelatedText = ""
    }
    
    /**
     This is done to avoid a bug in the SwiftyChrono package where some words cause a
     Fatal error in the SwiftyChrono/DEMonthNameLittleEndianParser.swift file
     */
    func avoidParserPanic(parsedResults: [String]) -> [String] {
        // Matches that cause the bug
        let matchesToAvoid = [
            "jan.",
            "feb.",
            "mär.",
            "apr.",
            "jun.",
            "jul.",
            "aug.",
            "sep.",
            "sept.",
            "okt.",
            "nov.",
            "dez."
        ]
         
        let matchesToAvoidPattern = "(?:" + matchesToAvoid.joined(separator: "|") + ")"
        var safeParsedResults: [String] = []
    
        for result in parsedResults {
            let isMatch = result.range(of: matchesToAvoidPattern,
                                       options: .regularExpression) != nil
            if isMatch {
                // Gets only the first 3 letters of the month to avoid the bug
                safeParsedResults.append(String(result.prefix(3)))
            } else {
                safeParsedResults.append(result)
            }
        }
        return safeParsedResults
    }
}
