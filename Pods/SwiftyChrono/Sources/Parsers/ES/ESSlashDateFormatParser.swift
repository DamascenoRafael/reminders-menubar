//
//  ESSlashDateFormatParser.swift
//  SwiftyChrono
//
//  Created by Jerry Chen on 2/6/17.
//  Copyright © 2017 Potix. All rights reserved.
//

import Foundation

private let PATTERN = "(\\W|^)" +
    "(?:" +
        "((?:domingo|dom|lunes|lun|martes|mar|mi[ée]rcoles|mie|jueves|jue|viernes|vie|s[áa]bado|sab))" +
        "\\s*\\,?\\s*" +
    ")?" +
    "([0-1]{0,1}[0-9]{1})[\\/\\.\\-]([0-3]{0,1}[0-9]{1})" +
    "(?:" +
        "[\\/\\.\\-]" +
        "([0-9]{4}|[0-9]{2})" +
    ")?" +
    "(\\W|$)"

private let openningGroup = 1
private let endingGroup = 6

// in Spanish we use day/month/year
private let weekdayGroup = 2
private let monthGroup = 4
private let dayGroup = 3
private let yearGroup = 5

public class ESSlashDateFormatParser: Parser {
    override var pattern: String { return PATTERN }
    override var language: Language { return .spanish }
    
    override public func extract(text: String, ref: Date, match: NSTextCheckingResult, opt: [OptionType: Int]) -> ParsedResult? {
        if (match.isNotEmpty(atRangeIndex: openningGroup) && match.string(from: text, atRangeIndex: openningGroup) == "/") ||
            (match.isNotEmpty(atRangeIndex: endingGroup) && match.string(from: text, atRangeIndex: endingGroup) == "/") {
            // Long skip, if there is some overlapping like:
            // XX[/YY/ZZ]
            // [XX/YY/]ZZ
            let match0 = match.range(at: 0)
            return ParsedResult.moveIndexMode(index: match0.location + match0.length)
        }
        
        let openGroup = match.isNotEmpty(atRangeIndex: openningGroup) ? match.string(from: text, atRangeIndex: openningGroup) : ""
        let endGroup = match.isNotEmpty(atRangeIndex: endingGroup) ? match.string(from: text, atRangeIndex: endingGroup) : ""
        let fullMatchText = match.string(from: text, atRangeIndex: 0)
        let index = match.range(at: 0).location + match.range(at: openningGroup).length
        let matchText = fullMatchText.substring(from: openGroup.count, to: fullMatchText.count - endGroup.count)
        var result = ParsedResult(ref: ref, index: index, text: matchText)
        
        if NSRegularExpression.isMatch(forPattern: "^\\d\\.\\d$", in: matchText) ||
            NSRegularExpression.isMatch(forPattern: "^\\d\\.\\d{1,2}\\.\\d{1,2}$", in: matchText) {
            return nil
        }
        
        // MM/dd -> OK
        // MM.dd -> NG
        if match.isEmpty(atRangeIndex: yearGroup) && (text.range(of: "/")?.isEmpty ?? true) {
            return nil
        }
        
        var year = match.isNotEmpty(atRangeIndex: yearGroup) ? Int(match.string(from: text, atRangeIndex: yearGroup)) ?? ref.year : ref.year
        var month = match.isNotEmpty(atRangeIndex: monthGroup) ? Int(match.string(from: text, atRangeIndex: monthGroup)) ?? 0 : 0
        var day = match.isNotEmpty(atRangeIndex: dayGroup) ? Int(match.string(from: text, atRangeIndex: dayGroup)) ?? 0 : 0
        
        if month < 1 || month > 12 {
            if month > 12 {
                // dd/mm/yyyy date format if day looks like a month, and month
                // looks like a day.
                if day >= 1 && day <= 12 && month >= 13 && month <= 31 {
                    // unambiguous
                    let tday = month
                    month = day
                    day = tday
                } else {
                    // both month and day are <= 12
                    return nil
                }
            }
        }
        
        if day < 1 || day > 31 {
            return nil
        }
        
        if year < 100 {
            year += year > 50 ? 1900 : 2000
        }
        
        result.start.assign(.day, value: day)
        result.start.assign(.month, value: month)
        result.start.assign(.year, value: year)
        
        //Day of week
        if match.isNotEmpty(atRangeIndex: weekdayGroup) {
            let weekday = match.string(from: text, atRangeIndex: weekdayGroup).lowercased()
            result.start.assign(.weekday, value: ES_WEEKDAY_OFFSET[weekday])
        }
        
        result.tags[.esSlashDateFormatParser] = true
        return result
    }
}

