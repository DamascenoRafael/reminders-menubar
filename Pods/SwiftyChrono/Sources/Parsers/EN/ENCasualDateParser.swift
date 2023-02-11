//
//  ENCasualDateParser.swift
//  SwiftyChrono
//
//  Created by Jerry Chen on 1/19/17.
//  Copyright © 2017 Potix. All rights reserved.
//

import Foundation

private let PATTERN = "(\\W|^)(now|today|tonight|last\\s*night|(?:tomorrow|tmr|yesterday)\\s*|tomorrow|tmr|yesterday)(?=\\W|$)"

public class ENCasualDateParser: Parser {
    override var pattern: String { return PATTERN }
    
    override public func extract(text: String, ref: Date, match: NSTextCheckingResult, opt: [OptionType: Int]) -> ParsedResult? {
        let (matchText, index) = matchTextAndIndex(from: text, andMatchResult: match)
        var result = ParsedResult(ref: ref, index: index, text: matchText)
        
        let refMoment = ref
        var startMoment = refMoment
        let lowerText = matchText.lowercased()
        
        if lowerText == "tonight" {
            // Normally means this coming midnight
            result.start.imply(.hour, to: 22)
            result.start.imply(.meridiem, to: 1)
            
        } else if NSRegularExpression.isMatch(forPattern: "^tomorrow|^tmr", in: lowerText) {
            // Check not "Tomorrow" on late night
            if refMoment.hour > 1 {
                startMoment = startMoment.added(1, .day)
            }
        } else if NSRegularExpression.isMatch(forPattern: "^yesterday", in: lowerText) {
            startMoment = startMoment.added(-1, .day)
        } else if NSRegularExpression.isMatch(forPattern: "last\\s*night", in: lowerText) {
            result.start.imply(.hour, to: 0)
            if refMoment.hour > 6 {
                startMoment = startMoment.added(-1, .day)
            }
        } else if NSRegularExpression.isMatch(forPattern: "now", in: lowerText) {
            result.start.imply(.hour, to: refMoment.hour)
            result.start.imply(.minute, to: refMoment.minute)
            result.start.imply(.second, to: refMoment.second)
            result.start.imply(.millisecond, to: refMoment.millisecond)
        }
        
        result.start.assign(.day, value: startMoment.day)
        result.start.assign(.month, value: startMoment.month)
        result.start.assign(.year, value: startMoment.year)
        result.tags[.enCasualDateParser] = true
        return result
    }
}
