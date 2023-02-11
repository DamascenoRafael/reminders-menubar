//
//  ENMonthNameLittleEndianParser.swift
//  SwiftyChrono
//
//  Created by Jerry Chen on 1/20/17.
//  Copyright © 2017 Potix. All rights reserved.
//

import Foundation

private let PATTERN = "(\\W|^)" +
    "(?:on\\s*?)?" +
    "(?:(Sunday|Monday|Tuesday|Wednesday|Thursday|Friday|Saturday|Sun|Mon|Tue|Wed|Thu|Fri|Sat)\\s*,?\\s*)?" +
    "(([0-9]{1,2})(?:st|nd|rd|th)?|\(EN_ORDINAL_WORDS_PATTERN))" +
    "(?:\\s*" +
        "(?:to|\\-|\\–|until|through|till|\\s)\\s*" +
        "(([0-9]{1,2})(?:st|nd|rd|th)?|\(EN_ORDINAL_WORDS_PATTERN))" +
    ")?\\s*(?:of)?\\s*" +
    "(Jan(?:uary|\\.)?|Feb(?:ruary|\\.)?|Mar(?:ch|\\.)?|Apr(?:il|\\.)?|May|Jun(?:e|\\.)?|Jul(?:y|\\.)?|Aug(?:ust|\\.)?|Sep(?:tember|\\.)?|Oct(?:ober|\\.)?|Nov(?:ember|\\.)?|Dec(?:ember|\\.)?)" +
    "(?:" +
        ",?\\s*([0-9]{1,4}(?![^\\s]\\d))" +
        "(\\s*(?:BE|AD|BC))?" +
    ")?" +
    "(?=\\W|$)"

private let weekdayGroup = 2
private let dateGroup = 3
private let dateNumGroup = 4
private let dateToGroup = 5
private let dateToNumGroup = 6
private let monthNameGroup = 7
private let yearGroup = 8
private let yearBeGroup = 9

public class ENMonthNameLittleEndianParser: Parser {
    override var pattern: String { return PATTERN }
    
    override public func extract(text: String, ref: Date, match: NSTextCheckingResult, opt: [OptionType: Int]) -> ParsedResult? {
        let (matchText, index) = matchTextAndIndex(from: text, andMatchResult: match)
        var result = ParsedResult(ref: ref, index: index, text: matchText)
        
        let month = EN_MONTH_OFFSET[match.string(from: text, atRangeIndex: monthNameGroup).lowercased()]!
        
        let day = match.isNotEmpty(atRangeIndex: dateNumGroup) ?
            Int(match.string(from: text, atRangeIndex: dateNumGroup))! :
            EN_ORDINAL_WORDS[match.string(from: text, atRangeIndex: dateGroup).trimmed().replacingOccurrences(of: "-", with: " ").lowercased()]!
        
        if match.isNotEmpty(atRangeIndex: yearGroup) {
            var year = Int(match.string(from: text, atRangeIndex: yearGroup))!
            
            if match.isNotEmpty(atRangeIndex: yearBeGroup) {
                let yearBe = match.string(from: text, atRangeIndex: yearBeGroup)
                
                if NSRegularExpression.isMatch(forPattern: "BE", in: yearBe) {
                    // Buddhist Era
                    year = year - 543
                } else if NSRegularExpression.isMatch(forPattern: "BC", in: yearBe) {
                    // Before Christ
                    year = -year
                }
            } else if year < 10 {
                // require single digit years to always have BC/AD
                return nil
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
            refMoment = refMoment.setOrAdded(ref.year, .year)
            
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
        
        // Text can be 'range' value. Such as '12 - 13 January 2012'
        if match.isNotEmpty(atRangeIndex: dateToGroup) {
            let endDate = match.isNotEmpty(atRangeIndex: dateToNumGroup) ?
                Int(match.string(from: text, atRangeIndex: dateToNumGroup)) :
                EN_ORDINAL_WORDS[match.string(from: text, atRangeIndex: dateToGroup).trimmed().replacingOccurrences(of: "-", with: " ").lowercased()]
            
            result.end = result.start.clone()
            result.end?.assign(.day, value: endDate)
        }
        
        result.tags[.enMonthNameLittleEndianParser] = true
        return result
    }
}
