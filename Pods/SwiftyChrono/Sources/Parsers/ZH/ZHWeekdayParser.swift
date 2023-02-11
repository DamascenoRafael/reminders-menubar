//
//  ZHWeekdayParser.swift
//  SwiftyChrono
//
//  Created by Jerry Chen on 2/18/17.
//  Copyright © 2017 Potix. All rights reserved.
//

import Foundation

private let PATTERN =
    "(上|今|下|這|呢|这)?" +
    "(?:個|个)?" +
    "(?:星期|禮拜|礼拜)" +
    "(\(ZH_WEEKDAY_OFFSET_PATTERN))"

private let prefixGroup = 1
private let weekdayGroup = 2

public class ZHWeekdayParser: Parser {
    override var pattern: String { return PATTERN }
    override var language: Language { return .chinese }
    
    override public func extract(text: String, ref: Date, match: NSTextCheckingResult, opt: [OptionType: Int]) -> ParsedResult? {
        let (matchText, index) = matchTextAndIndexForCHHant(from: text, andMatchResult: match)
        var result = ParsedResult(ref: ref, index: index, text: matchText)
        
        let dayOfWeek = match.string(from: text, atRangeIndex: weekdayGroup)
        guard let offset = ZH_WEEKDAY_OFFSET[dayOfWeek] else {
            return nil
        }
        
        var modifier = ""
        let prefix = match.isNotEmpty(atRangeIndex: prefixGroup) ? match.string(from: text, atRangeIndex: prefixGroup) : ""
        
        if prefix == "上" {
            modifier = "last"
        } else if prefix == "下" {
            modifier = "next"
        } else if prefix == "今" || prefix == "這" || prefix == "呢" || prefix == "这" {
            modifier = "this"
        }
        
        result = updateParsedComponent(result: result, ref: ref, offset: offset, modifier: modifier)
        result.tags[.zhHantWeekdayParser] = true
        return result
    }
}
