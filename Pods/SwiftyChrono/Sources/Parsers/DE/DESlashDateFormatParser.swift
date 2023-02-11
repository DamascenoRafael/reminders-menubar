//
//  DESlashDateFormatParser.swift
//  SwiftyChrono
//
//  Created by Jerry Chen on 2/8/17.
//  Copyright © 2017 Potix. All rights reserved.
//
import Foundation

private let PATTERN = "(\\W|^)" +
    "(?:" +
        "(?:(?:am)\\s*?)?" +
        "(\(DE_WEEKDAY_WORDS_PATTERN)(?:.?,?\\s*de[rnms])?)" +
        "\\s*\\,?\\s*" +
    ")?" +
    "(?:" +
        "([0-3]{0,1}[0-9]{1})\\.([0-3]{0,1}[0-9]{1})" +
        "(?:" +
            "\\." +
            "([0-9]{4}|[0-9]{2})" +
        ")?" +
    "|" +
        "(?:" +
            "([0-9]{4}|[0-9]{2})" +
            "\\-" +
        ")?" +
        "([0-3]{0,1}[0-9]{1})\\-([0-3]{0,1}[0-9]{1})" +
    ")?" +
    "(\\W|$)"

private let openningGroup = 1
private let endingGroup = 9

private let weekdayGroup = 2

private let day1Group = 3
private let month1Group = 4
private let year1Group = 5

private let year2Group = 6
private let month2Group = 7
private let day2Group = 8

public class DESlashDateFormatParser: Parser {
    override var pattern: String { return PATTERN }
    override var language: Language { return .german }
    
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
        
        var year: Int
        var month: Int
        var day: Int
        
        if match.isNotEmpty(atRangeIndex: day1Group) {
            year = match.isNotEmpty(atRangeIndex: year1Group) ? Int(match.string(from: text, atRangeIndex: year1Group)) ?? ref.year : ref.year
            month = match.isNotEmpty(atRangeIndex: month1Group) ? Int(match.string(from: text, atRangeIndex: month1Group)) ?? 0 : 0
            day = match.isNotEmpty(atRangeIndex: day1Group) ? Int(match.string(from: text, atRangeIndex: day1Group)) ?? 0 : 0
        } else {
            year = match.isNotEmpty(atRangeIndex: year2Group) ? Int(match.string(from: text, atRangeIndex: year2Group)) ?? ref.year : ref.year
            month = match.isNotEmpty(atRangeIndex: month2Group) ? Int(match.string(from: text, atRangeIndex: month2Group)) ?? 0 : 0
            day = match.isNotEmpty(atRangeIndex: day2Group) ? Int(match.string(from: text, atRangeIndex: day2Group)) ?? 0 : 0
        }
        
        
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
            result.start.assign(.weekday, value: DE_WEEKDAY_OFFSET[weekday])
        }
        
        result.tags[.deSlashDateFormatParser] = true
        return result
    }
}

