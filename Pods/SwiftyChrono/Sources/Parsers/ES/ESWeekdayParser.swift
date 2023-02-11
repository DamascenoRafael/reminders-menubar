//
//  ESWeekdayParser.swift
//  SwiftyChrono
//
//  Created by Jerry Chen on 2/6/17.
//  Copyright © 2017 Potix. All rights reserved.
//

import Foundation

private let PATTERN = "(\\W|^)" +
    "(?:(?:\\,|\\(|\\（)\\s*)?" +
    "(?:(este|pasado|pr[oó]ximo)\\s*)?" +
    "(\(ES_WEEKDAY_OFFSET.keys.joined(separator: "|")))" +
    "(?:\\s*(?:\\,|\\)|\\）))?" +
    "(?:\\s*(este|pasado|pr[óo]ximo)\\s*week)?" +
    "(?=\\W|$)"

private let prefixGroup = 2
private let weekdayGroup = 3
private let postfixGroup = 4

public class ESWeekdayParser: Parser {
    override var pattern: String { return PATTERN }
    override var language: Language { return .spanish }
    
    override public func extract(text: String, ref: Date, match: NSTextCheckingResult, opt: [OptionType: Int]) -> ParsedResult? {
        let (matchText, index) = matchTextAndIndex(from: text, andMatchResult: match)
        var result = ParsedResult(ref: ref, index: index, text: matchText)
        
        let dayOfWeek = match.string(from: text, atRangeIndex: weekdayGroup).lowercased()
        guard let offset = ES_WEEKDAY_OFFSET[dayOfWeek] else {
            return nil
        }
        
        let prefix: String? = match.isNotEmpty(atRangeIndex: prefixGroup) ? match.string(from: text, atRangeIndex: prefixGroup) : nil
        let postfix: String? = match.isNotEmpty(atRangeIndex: postfixGroup) ? match.string(from: text, atRangeIndex: postfixGroup) : nil
        var modifier = ""
        if prefix != nil || postfix != nil {
            let norm = (prefix ?? postfix ?? "").lowercased()
            
            if norm == "pasado" {
                modifier = "last"
            }
            else if norm == "próximo" || norm == "proximo" {
                modifier = "next"
            }
            else if norm == "este" {
                modifier =  "this"
            }
        }
        
        result = updateParsedComponent(result: result, ref: ref, offset: offset, modifier: modifier)
        result.tags[.esWeekdayParser] = true
        return result
    }
}

