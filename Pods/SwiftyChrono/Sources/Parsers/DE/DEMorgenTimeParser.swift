//
//  DEMorgenTimeParser.swift
//  SwiftyChrono
//
//  Created by Jerry Chen on 2/18/17.
//  Copyright © 2017 Potix. All rights reserved.
//

import Foundation

/* this is a white list for morning cases
 * e.g.
 * this morning => heute Morgen
 * tomorrow morning => Morgen früh
 * friday morning => Freitag Morgen
 * last morning => letzten Morgen
 */
private let PATTERN = "(\\W|^)((?:heute|letzten)\\s*Morgen|Morgen\\s*früh|\(DE_WEEKDAY_WORDS_PATTERN)\\s*Morgen)"
private let timeMatch = 2

public class DEMorgenTimeParser: Parser {
    override var pattern: String { return PATTERN }
    override var language: Language { return .german }
    
    override public func extract(text: String, ref: Date, match: NSTextCheckingResult, opt: [OptionType: Int]) -> ParsedResult? {
        let (matchText, index) = matchTextAndIndex(from: text, andMatchResult: match)
        var result = ParsedResult(ref: ref, index: index, text: matchText)
        
        result.start.imply(.hour, to: opt[.morning] ?? 6)
        
        let time = match.string(from: text, atRangeIndex: timeMatch).lowercased()
        
        if time.hasPrefix("letzten") {
            result.start.imply(.day, to: ref.day - 1)
        } else if time.hasSuffix("früh") {
            result.start.imply(.day, to: ref.day + 1)
        } else {
            if let weekday = DE_WEEKDAY_OFFSET[time.substring(from: 0, to: time.count - "Morgen".count).trimmed()] {
                
                result.start.assign(.weekday, value: weekday)
            }
        }
        
        result.tags[.deMorgenTimeParser] = true
        return result
    }
}
