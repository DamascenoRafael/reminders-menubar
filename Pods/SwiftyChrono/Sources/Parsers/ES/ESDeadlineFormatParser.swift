//
//  ESDeadlineFormatParser.swift
//  SwiftyChrono
//
//  Created by Jerry Chen on 2/6/17.
//  Copyright © 2017 Potix. All rights reserved.
//

import Foundation

private let PATTERN = "(\\W|^)(dentro\\s*de|en)\\s*([0-9]+|medi[oa]|una?)\\s*(minutos?|horas?|d[ií]as?)\\s*(?=(?:\\W|$))"



public class ESDeadlineFormatParser: Parser {
    override var pattern: String { return PATTERN }
    override var language: Language { return .spanish }
    
    override public func extract(text: String, ref: Date, match: NSTextCheckingResult, opt: [OptionType: Int]) -> ParsedResult? {
        let (matchText, index) = matchTextAndIndex(from: text, andMatchResult: match)
        var result = ParsedResult(ref: ref, index: index, text: matchText)
        result.tags[.esDeadlineFormatParser] = true
        
        let number: Int
        let numberText = match.string(from: text, atRangeIndex: 3).lowercased()
        let parsedNumber = Int(numberText)
        
        if parsedNumber == nil {
            if NSRegularExpression.isMatch(forPattern: "medi", in: numberText) {
                number = HALF
            } else {
                number = 1
            }
        } else {
            number = parsedNumber!
        }
        
        let number4 = match.string(from: text, atRangeIndex: 4).lowercased()
        var date = ref
        if NSRegularExpression.isMatch(forPattern: "d[ií]a", in: number4) {
            date = number != HALF ? date.added(number, .day) : date.added(12, .hour)
            
            result.start.assign(.year, value: date.year)
            result.start.assign(.month, value: date.month)
            result.start.assign(.day, value: date.day)
            return result;
        }
        
        
        if NSRegularExpression.isMatch(forPattern: "hora", in: number4) {
            date = number != HALF ? date.added(number, .hour) : date.added(30, .minute)
        } else if NSRegularExpression.isMatch(forPattern: "minuto", in: number4) {
            date = number != HALF ? date.added(number, .minute) : date.added(30, .second)
        }
        
        result.start.imply(.year, to: date.year)
        result.start.imply(.month, to: date.month)
        result.start.imply(.day, to: date.day)
        result.start.assign(.hour, value: date.hour)
        result.start.assign(.minute, value: date.minute)
        
        return result
    }
}

