//
//  ENISOFormatParser.swift
//  SwiftyChrono
//
//  Created by Jerry Chen on 1/20/17.
//  Copyright © 2017 Potix. All rights reserved.
//

import Foundation

/*
 ISO 8601
 http://www.w3.org/TR/NOTE-datetime
 - YYYY-MM-DD
 - YYYY-MM-DDThh:mmTZD
 - YYYY-MM-DDThh:mm:ssTZD
 - YYYY-MM-DDThh:mm:ss.sTZD
 - TZD = (Z or +hh:mm or -hh:mm)
 */

private let PATTERN = "(\\W|^)" +
    "([0-9]{4})\\-([0-9]{1,2})\\-([0-9]{1,2})" +
    "(?:T" + //..
        "([0-9]{1,2}):([0-9]{1,2})" + // hh:mm
        "(?::([0-9]{1,2})(?:\\.(\\d{1,4}))?)?" + // :ss.s
        "(?:Z|([+-]\\d{2}):?(\\d{2})?)?" + // TZD (Z or ±hh:mm or ±hhmm or ±hh)
    ")?" + //..
    "(?=\\W|$)"

private let yearNumberGroup = 2
private let monthNumberGroup = 3
private let dayNumberGroup  = 4
private let hourNumberGroup  = 5
private let minuteNumberGroup = 6
private let secondNumberGroup = 7
private let millisecondNumberGroup = 8
private let tzdHourOffsetGroup = 9
private let tzdMinuteOffsetGroup = 10

public class ENISOFormatParser: Parser {
    override var pattern: String { return PATTERN }
    
    override public func extract(text: String, ref: Date, match: NSTextCheckingResult, opt: [OptionType: Int]) -> ParsedResult? {
        let (matchText, index) = matchTextAndIndex(from: text, andMatchResult: match)
        var result = ParsedResult(ref: ref, index: index, text: matchText)
        
        result.start.assign(.year, value: Int(match.string(from: text, atRangeIndex: yearNumberGroup)))
        result.start.assign(.month, value: Int(match.string(from: text, atRangeIndex: monthNumberGroup)))
        result.start.assign(.day, value: Int(match.string(from: text, atRangeIndex: dayNumberGroup)))
        
        guard let month = result.start[.month], let day = result.start[.day] else {
            return nil
        }
        
        if month > 12 || month < 1 || day > 31 || day < 1 {
            return nil
        }
        
        if match.isNotEmpty(atRangeIndex: hourNumberGroup) {
            result.start.assign(.hour, value: Int(match.string(from: text, atRangeIndex: hourNumberGroup)))
            result.start.assign(.minute, value: Int(match.string(from: text, atRangeIndex: minuteNumberGroup)))
            
            if match.isNotEmpty(atRangeIndex: secondNumberGroup) {
                result.start.assign(.second, value: Int(match.string(from: text, atRangeIndex: secondNumberGroup)))
            }
            
            if match.isNotEmpty(atRangeIndex: millisecondNumberGroup) {
                result.start.assign(.millisecond, value: Int(match.string(from: text, atRangeIndex: millisecondNumberGroup)))
            }
            
            if match.isNotEmpty(atRangeIndex: tzdHourOffsetGroup) {
                let hourOffset = Int(match.string(from: text, atRangeIndex: tzdHourOffsetGroup)) ?? 0
                let minuteOffset = match.isNotEmpty(atRangeIndex: tzdMinuteOffsetGroup) ? Int(match.string(from: text, atRangeIndex: tzdMinuteOffsetGroup)) ?? 0 : 0
                
                var offset = hourOffset * 60
                offset = offset + (offset < 0 ? -minuteOffset : minuteOffset)
                
                result.start.assign(.timeZoneOffset, value: offset)
            } else {
                result.start.assign(.timeZoneOffset, value: 0)
            }
        }
        
        result.tags[.enCasualTimeParser] = true
        return result
    }
}
