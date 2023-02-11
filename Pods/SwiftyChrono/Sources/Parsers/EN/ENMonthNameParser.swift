//
//  ENMonthNameParser.swift
//  SwiftyChrono
//
//  Created by Jerry Chen on 1/20/17.
//  Copyright © 2017 Potix. All rights reserved.
//

import Foundation

private let PATTERN = "(^|\\D\\s+|[^\\w\\s])" +
    "(Jan\\.?|January|Feb\\.?|February|Mar\\.?|March|Apr\\.?|April|May\\.?|Jun\\.?|June|Jul\\.?|July|Aug\\.?|August|Sep\\.?|Sept\\.?|September|Oct\\.?|October|Nov\\.?|November|Dec\\.?|December)" +
    "\\s*" +
    "(?:" +
        "[,-]?\\s*([0-9]{4})(\\s*BE|AD|BC)?" +
    ")?" +
    "(?=[^\\s\\w]|\\s+[^0-9]|\\s+$|$)"

private let monthNameGroup = 2
private let yearGroup = 3
private let yearBeGroup = 4

public class ENMonthNameParser: Parser {
    override var pattern: String { return PATTERN }
    
    override public func extract(text: String, ref: Date, match: NSTextCheckingResult, opt: [OptionType: Int]) -> ParsedResult? {
        let (matchText, index) = matchTextAndIndex(from: text, andMatchResult: match)
        var result = ParsedResult(ref: ref, index: index, text: matchText)
        
        let month = EN_MONTH_OFFSET[match.string(from: text, atRangeIndex: monthNameGroup).lowercased()]!
        let day = 1
        
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
            
            result.start.imply(.day, to: day)
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
            
            result.start.imply(.day, to: day)
            result.start.assign(.month, value: month)
            result.start.imply(.year, to: refMoment.year)
        }
        
        result.tags[.enMonthNameParser] = true
        return result
    }
}
