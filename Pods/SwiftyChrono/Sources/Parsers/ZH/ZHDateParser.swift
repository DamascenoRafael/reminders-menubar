//
//  ZHHantDateParser.swift
//  SwiftyChrono
//
//  Created by Jerry Chen on 2/18/17.
//  Copyright © 2017 Potix. All rights reserved.
//

import Foundation

private let PATTERN =
    "(\\d{2,4}|\(ZH_NUMBER_PATTERN){2,4})?" +
    "(?:\\s*)" +
    "(?:年)?" +
    "(?:[\\s|,|，]*)" +
    "(\\d{1,2}|\(ZH_NUMBER_PATTERN){1,2})" +
    "(?:\\s*)" +
    "(?:月)" +
    "(?:\\s*)" +
    "(\\d{1,2}|\(ZH_NUMBER_PATTERN){1,2})?" +
    "(?:\\s*)" +
    "(?:日|號|号)?"

private let yearGroup = 1
private let monthGroup = 2
private let dayGroup = 3

public class ZHDateParser: Parser {
    override var pattern: String { return PATTERN }
    override var language: Language { return .chinese }
    
    override public func extract(text: String, ref: Date, match: NSTextCheckingResult, opt: [OptionType: Int]) -> ParsedResult? {
        let (matchText, index) = matchTextAndIndexForCHHant(from: text, andMatchResult: match)
        var result = ParsedResult(ref: ref, index: index, text: matchText)
        
        let refMoment = ref
        let startMoment = refMoment
        
        //Month
        let monthString = match.string(from: text, atRangeIndex: monthGroup)
        guard let month = NSRegularExpression.isMatch(forPattern: "\\d+", in: monthString) ? Int(monthString) : ZHStringToNumber(text: monthString) else {
            return nil
        }
        result.start.assign(.month, value: month)
        
        //Day
        if match.isNotEmpty(atRangeIndex: dayGroup) {
            let dayString = match.string(from: text, atRangeIndex: dayGroup)
            guard let day = NSRegularExpression.isMatch(forPattern: "\\d+", in: dayString) ? Int(dayString) : ZHStringToNumber(text: dayString) else {
                return nil
            }
            
            result.start.assign(.day, value: day)
        } else {
            result.start.imply(.day, to: startMoment.day)
        }
        
        //Year
        if match.isNotEmpty(atRangeIndex: yearGroup) {
            let yearString = match.string(from: text, atRangeIndex: yearGroup)
            guard let year = NSRegularExpression.isMatch(forPattern: "\\d+", in: yearString) ? Int(yearString) : ZHStringToYear(text: yearString) else {
                return nil
            }
            
            result.start.assign(.year, value: year)
        } else {
            result.start.imply(.year, to: startMoment.year)
        }
        
        result.tags[.zhHantDateParser] = true
        return result
    }
}
