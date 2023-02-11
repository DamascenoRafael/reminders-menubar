//
//  DETimeAgoFormatParser.swift
//  SwiftyChrono
//
//  Created by Jerry Chen on 2/8/17.
//  Copyright © 2017 Potix. All rights reserved.
//

import Foundation

private let PATTERN = "(\\W|^)vor\\s*" +
    "(\(DE_INTEGER_WORDS_PATTERN)|[0-9]+|\(DE_INTEGER1_WORDS_PATTERN)?(?:\\s*(?:wenige[r|n]?|einigen?|paar))?|(?:\(DE_INTEGER1_WORDS_PATTERN))?\\s*halbe(?:n|s)?)\\s*" +
    "(sekunden?|minuten?|stunden?|tag(?:en|e)?|wochen?|monat(?:en|e|s)?|jahr(?:en|(?:es)|e)??)(?=(?:\\W|$))"



public class DETimeAgoFormatParser: Parser {
    override var pattern: String { return PATTERN }
    override var language: Language { return .german }
    
    override public func extract(text: String, ref: Date, match: NSTextCheckingResult, opt: [OptionType: Int]) -> ParsedResult? {
        let idx = match.range(at: 0).location
        if idx > 0 && NSRegularExpression.isMatch(forPattern: "\\w", in: text.substring(from: idx - 1, to: idx)) {
            return nil
        }
        
        let (matchText, index) = matchTextAndIndex(from: text, andMatchResult: match)
        var result = ParsedResult(ref: ref, index: index, text: matchText)
        
        let number: Int
        let numberText = match.string(from: text, atRangeIndex: 2).lowercased()
        if let number0 = DE_INTEGER_WORDS[numberText] {
            number = number0
        } else if DE_INTEGER1_WORDS[numberText] != nil {
            number = 1
        } else if NSRegularExpression.isMatch(forPattern: "wenige|einige|paar", in: numberText) {
            number = 3
        } else if NSRegularExpression.isMatch(forPattern: "halbe", in: numberText) {
            number = HALF
        } else {
            number = Int(numberText)!
        }
        
        var date = ref
        let matchText3 = match.string(from: text, atRangeIndex: 3)
        func ymdResult() -> ParsedResult {
            result.start.imply(.day, to: date.day)
            result.start.imply(.month, to: date.month)
            result.start.imply(.year, to: date.year)
            result.start.assign(.hour, value: date.hour)
            result.start.assign(.minute, value: date.minute)
            result.start.assign(.second, value: date.second)
            result.tags[.deTimeAgoFormatParser] = true
            return result
        }
        if NSRegularExpression.isMatch(forPattern: "stunde", in: matchText3) {
            date = number != HALF ? date.added(-number, .hour) : date.added(-30, .minute)
            return ymdResult()
        } else if NSRegularExpression.isMatch(forPattern: "minute", in: matchText3) {
            date = number != HALF ? date.added(-number, .minute) : date.added(-30, .second)
            return ymdResult()
        } else if NSRegularExpression.isMatch(forPattern: "sekunde", in: matchText3) {
            date = number != HALF ? date.added(-number, .second) : date.added(-HALF_SECOND_IN_MS, .nanosecond)
            return ymdResult()
        }
        
        if NSRegularExpression.isMatch(forPattern: "woche", in: matchText3) {
            date = number != HALF ? date.added(-number * 7, .day) : date.added(-3, .day).added(-12, .hour)
            
            result.start.imply(.day, to: date.day)
            result.start.imply(.month, to: date.month)
            result.start.imply(.year, to: date.year)
            result.start.imply(.weekday, to: date.weekday)
            result.tags[.deTimeAgoFormatParser] = true
            return result
        } else if NSRegularExpression.isMatch(forPattern: "tag", in: matchText3) {
            date = number != HALF ? date.added(-number, .day) : date.added(-12, .hour)
        } else if NSRegularExpression.isMatch(forPattern: "monat", in: matchText3) {
            date = number != HALF ? date.added(-number, .month) : date.added(-(date.numberOf(.day, inA: .month) ?? 30)/2, .day)
        } else if NSRegularExpression.isMatch(forPattern: "jahr", in: matchText3) {
            date = number != HALF ? date.added(-number, .year) : date.added(-6, .month)
        }
        
        result.start.assign(.day, value: date.day)
        result.start.assign(.month, value: date.month)
        result.start.assign(.year, value: date.year)
        result.tags[.deTimeAgoFormatParser] = true
        return result
    }
}

