//
//  JPCasualDateParser.swift
//  SwiftyChrono
//
//  Created by Jerry Chen on 2/6/17.
//  Copyright © 2017 Potix. All rights reserved.
//

import Foundation

private let PATTERN = "今日|当日|昨日|明日|今夜|今夕|今晩|今朝"

public class JPCasualDateParser: Parser {
    override var pattern: String { return PATTERN }
    override var language: Language { return .japanese }
    
    override public func extract(text: String, ref: Date, match: NSTextCheckingResult, opt: [OptionType: Int]) -> ParsedResult? {
        let index = match.range(at: 0).location
        let matchText = match.string(from: text, atRangeIndex: 0)
        var result = ParsedResult(ref: ref, index: index, text: matchText)
        
        let refMoment = ref
        var startMoment = refMoment
        
        if matchText == "今夜" || matchText == "今夕" || matchText == "今晩" {
            // Normally means this coming midnight
            result.start.imply(.hour, to: 22)
            result.start.imply(.meridiem, to: 1)
            
        } else if matchText == "明日" {
            // Check not "Tomorrow" on late night
            if refMoment.hour > 4 {
                startMoment = startMoment.added(1, .day)
            }
        } else if matchText == "昨日" {
            startMoment = startMoment.added(-1, .day)
        } else if NSRegularExpression.isMatch(forPattern: "今朝", in: matchText) {
            result.start.imply(.hour, to: 6)
            result.start.imply(.meridiem, to: 0)
        }
        
        result.start.assign(.day, value: startMoment.day)
        result.start.assign(.month, value: startMoment.month)
        result.start.assign(.year, value: startMoment.year)
        result.tags[.jpCasualDateParser] = true
        return result
    }
}

