//
//  ENMonthNameMiddleEndianParser.swift
//  SwiftyChrono
//
//  Created by Jerry Chen on 1/20/17.
//  Copyright © 2017 Potix. All rights reserved.
//

import Foundation

private let PATTERN = "(\\W|^)" +
    "(?:" +
        "(?:on\\s*?)?" +
        "(Sunday|Monday|Tuesday|Wednesday|Thursday|Friday|Saturday|Sun\\.?|Mon\\.?|Tue\\.?|Wed\\.?|Thu\\.?|Fri\\.?|Sat\\.?)" +
    "\\s*,?\\s*)?" +
    "(Jan\\.?|January|Feb\\.?|February|Mar\\.?|March|Apr\\.?|April|May\\.?|Jun\\.?|June|Jul\\.?|July|Aug\\.?|August|Sep\\.?|Sept\\.?|September|Oct\\.?|October|Nov\\.?|November|Dec\\.?|December)" +
    "\\s*" +
    "(([0-9]{1,2})(?:st|nd|rd|th)?|\(EN_ORDINAL_WORDS_PATTERN))\\s*" +
    "(?:" +
        "(?:to|\\-)\\s*" +
        "(([0-9]{1,2})(?:st|nd|rd|th)?| \(EN_ORDINAL_WORDS_PATTERN))\\s*" +
    ")?" +
    "(?:" +
        "\\s*,?\\s*(?:([0-9]{4})\\s*(BE|AD|BC)?|([0-9]{1,4})\\s*(AD|BC))\\s*" +
    ")?" +
    "(?=\\W|$)(?!\\:\\d)"

private let weekdayGroup = 2
private let monthNameGroup = 3
private let dateGroup = 4
private let dateNumGroup = 5
private let dateToGroup = 6
private let dateToNumGroup = 7
private let yearGroup = 8
private let yearBeGroup = 9
private let yearGroup2 = 10
private let yearBeGroup2 = 11

public class ENMonthNameMiddleEndianParser: Parser {
    override var pattern: String { return PATTERN }
    
    override public func extract(text: String, ref: Date, match: NSTextCheckingResult, opt: [OptionType: Int]) -> ParsedResult? {
        let (matchText, index) = matchTextAndIndex(from: text, andMatchResult: match)
        var result = ParsedResult(ref: ref, index: index, text: matchText)
        
        let month = EN_MONTH_OFFSET[match.string(from: text, atRangeIndex: monthNameGroup).lowercased()]!
        let day = match.isNotEmpty(atRangeIndex: dateNumGroup) ?
            Int(match.string(from: text, atRangeIndex: dateNumGroup))! :
            EN_ORDINAL_WORDS[match.string(from: text, atRangeIndex: dateGroup).replacingOccurrences(of: "-", with: " ").lowercased()]!
        
        let yearGroupNotEmpty = match.isNotEmpty(atRangeIndex: yearGroup)
        if yearGroupNotEmpty || match.isNotEmpty(atRangeIndex: yearGroup2) {
            var year = Int(match.string(from: text, atRangeIndex: yearGroupNotEmpty ? yearGroup : yearGroup2))!
            
            let yearBE = match.isNotEmpty(atRangeIndex: yearBeGroup) ? match.string(from: text, atRangeIndex: yearBeGroup) : match.isNotEmpty(atRangeIndex: yearBeGroup2) ? match.string(from: text, atRangeIndex: yearBeGroup2) : ""
            if !yearBE.isEmpty {
                if NSRegularExpression.isMatch(forPattern: "BE", in: yearBE) {
                    // Buddhist Era
                    year = year - 543
                } else if NSRegularExpression.isMatch(forPattern: "BC", in: yearBE) {
                    // Before Christ
                    year = -year
                }
            } else if year < 100 {
                year += 2000
            }
            
            result.start.assign(.day, value: day)
            result.start.assign(.month, value: month)
            result.start.assign(.year, value: year)
        } else {
            //Find the most appropriated year
            var refMoment = ref
            refMoment = refMoment.setOrAdded(month, .month)
            refMoment = refMoment.setOrAdded(day, .day)
            
            let nextYear = refMoment.added(1, .year)
            let lastYear = refMoment.added(-1, .year)
            if abs(nextYear.differenceOfTimeInterval(to: ref)) < abs(refMoment.differenceOfTimeInterval(to: ref)) {
                refMoment = nextYear
            } else if abs(lastYear.differenceOfTimeInterval(to: ref)) < abs(refMoment.differenceOfTimeInterval(to: ref)) {
                refMoment = lastYear
            }
            
            result.start.assign(.day, value: day)
            result.start.assign(.month, value: month)
            result.start.imply(.year, to: refMoment.year)
        }
        
        // Weekday component
        if match.isNotEmpty(atRangeIndex: weekdayGroup) {
            let weekday = EN_WEEKDAY_OFFSET[match.string(from: text, atRangeIndex: weekdayGroup).lowercased()]
            result.start.assign(.weekday, value: weekday)
        }
        
        // Text can be 'range' value. Such as 'January 12 - 13, 2012'
        if match.isNotEmpty(atRangeIndex: dateToGroup) {
            let endDate = match.isNotEmpty(atRangeIndex: dateToNumGroup) ?
                Int(match.string(from: text, atRangeIndex: dateToNumGroup)) :
                EN_ORDINAL_WORDS[match.string(from: text, atRangeIndex: dateToGroup).trimmed().replacingOccurrences(of: "-", with: " ").lowercased()]
            
            result.end = result.start.clone()
            result.end?.assign(.day, value: endDate)
        }
        
        result.tags[.enMonthNameMiddleEndianParser] = true
        return result
    }
}
