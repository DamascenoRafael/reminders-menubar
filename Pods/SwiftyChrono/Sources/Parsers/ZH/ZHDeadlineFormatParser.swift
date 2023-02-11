//
//  ZHDeadlineFormatParser.swift
//  SwiftyChrono
//
//  Created by Jerry Chen on 2/18/17.
//  Copyright © 2017 Potix. All rights reserved.
//

import Foundation

private let PATTERN =
    "(\\d+|\(ZH_NUMBER_PATTERN)+|半|幾|几)(?:\\s*)" +
    "(?:個|个)?" +
    "(秒(?:鐘|钟)?|分鐘|小時|鐘|日|天|星期|禮拜|月|年|分钟|小时|钟|礼拜)" +
		"(?:(?:之|過)?後|(?:之)?(內|内)|(?:之|过)?后)"

private let numberGroup = 1
private let unitGroup = 2

public class ZHDeadlineFormatParser: Parser {
    override var pattern: String { return PATTERN }
    override var language: Language { return .chinese }
    
    override public func extract(text: String, ref: Date, match: NSTextCheckingResult, opt: [OptionType: Int]) -> ParsedResult? {
        let (matchText, index) = matchTextAndIndexForCHHant(from: text, andMatchResult: match)
        var result = ParsedResult(ref: ref, index: index, text: matchText)
        
        let refMoment = ref
        let startMoment = refMoment
        
        let numberString = match.string(from: text, atRangeIndex: numberGroup)
        let number: Int
        if numberString == "幾" || numberString == "几" {
            number = 3
        } else if numberString == "半" {
            number = HALF
        } else if !NSRegularExpression.isMatch(forPattern: "\\d+", in: numberString) {
            number = ZHStringToNumber(text: numberString)
        } else {
            if let intValue = Int(numberString) {
                number = intValue
            } else {
                return nil
            }
        }
        
        var date = ref
        var unit = match.string(from: text, atRangeIndex: unitGroup)
        var unitAbbr = unit.firstString ?? ""
        result.tags[.zhHantDeadlineFormatParser] = true
        
        func ymdResult() -> ParsedResult {
            result.start.assign(.year, value: date.year)
            result.start.assign(.month, value: date.month)
            result.start.assign(.day, value: date.day)
            return result
        }
        
        if unitAbbr == "日" || unitAbbr == "天" {
            date = number == HALF ? date.added(12, .hour) : date.added(number, .day)
            return ymdResult()
        } else if unitAbbr == "星" || unitAbbr == "禮" || unitAbbr == "礼"  {
            date = number == HALF ? date.added(3, .day).added(12, .hour) : date.added(number * 7, .day)
            return ymdResult()
        } else if unitAbbr == "月" {
            date = number == HALF ? date.added((date.numberOf(.day, inA: .month) ?? 30)/2, .day) : date.added(number, .month)
            return ymdResult()
        } else if unitAbbr == "年" {
            date = number == HALF ? date.added(6, .month) : date.added(number, .year)
            return ymdResult()
        }
        
        
        if unitAbbr == "秒" {
            date = number == HALF ? date.added(HALF_SECOND_IN_MS, .nanosecond) : date.added(number, .second)
        } else if unitAbbr == "分" {
            date = number == HALF ? date.added(30, .second) : date.added(number, .minute)
        } else if unitAbbr == "小" || unitAbbr == "鐘" || unitAbbr == "钟" {
            date = number == HALF ? date.added(30, .minute) : date.added(number, .hour)
        }
        
        result.start.imply(.year, to: date.year)
        result.start.imply(.month, to: date.month)
        result.start.imply(.day, to: date.day)
        result.start.assign(.hour, value: date.hour)
        result.start.assign(.minute, value: date.minute)
        result.start.assign(.second, value: date.second)
        
        return result
    }
}
