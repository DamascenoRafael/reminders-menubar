//
//  ZHCasualDateParser.swift
//  SwiftyChrono
//
//  Created by Jerry Chen on 2/18/17.
//  Copyright © 2017 Potix. All rights reserved.
//

import Foundation

private let PATTERN =
    "(而家|立(?:刻|即)|即刻)|" +
    "(今|明|聽|昨|尋|琴)(早|朝|晚)|" +
    "(上(?:午|晝)|朝(?:早)|早(?:上)|下(?:午|晝)|晏(?:晝)|晚(?:上)|夜(?:晚)?|中(?:午)|凌(?:晨))|" +
    "(今|明|聽|昨|尋|琴)(?:日|天)" +
    "(?:[\\s|,|，]*)" +
    "(?:(上(?:午|晝)|朝(?:早)|早(?:上)|下(?:午|晝)|晏(?:晝)|晚(?:上)|夜(?:晚)?|中(?:午)|凌(?:晨)))?"

private let nowGroup = 1
private let dayGroup1 = 2
private let timeGroup1 = 3
private let timeGroup2 = 4
private let dayGroup3 = 5
private let timeGroup3 = 6

public class ZHCasualDateParser: Parser {
    override var pattern: String { return PATTERN }
    override var language: Language { return .chinese }
    
    override public func extract(text: String, ref: Date, match: NSTextCheckingResult, opt: [OptionType: Int]) -> ParsedResult? {
        let (matchText, index) = matchTextAndIndexForCHHant(from: text, andMatchResult: match)
        var result = ParsedResult(ref: ref, index: index, text: matchText)
        
        let refMoment = ref
        var startMoment = refMoment
        
        if match.isNotEmpty(atRangeIndex: nowGroup) {
            result.start.imply(.hour, to: refMoment.hour)
            result.start.imply(.minute, to: refMoment.minute)
            result.start.imply(.second, to: refMoment.second)
            result.start.imply(.millisecond, to: refMoment.millisecond)
        } else if match.isNotEmpty(atRangeIndex: dayGroup1) {
            let day1 = match.string(from: text, atRangeIndex: dayGroup1)
            let time1 = match.string(from: text, atRangeIndex: timeGroup1)
            
            if day1 == "明" || day1 == "聽" {
                // Check not "Tomorrow" on late night
                if refMoment.hour > 1 {
                    startMoment = startMoment.added(1, .day)
                }
            } else if day1 == "昨" || day1 == "尋" || day1 == "琴" {
                startMoment = startMoment.added(-1, .day)
            }
            
            if time1 == "早" || time1 == "朝" {
                result.start.imply(.hour, to: 6)
            } else if time1 == "晚" {
                result.start.imply(.hour, to: 22)
                result.start.imply(.meridiem, to: 1)
            }
            
        } else if match.isNotEmpty(atRangeIndex: timeGroup2) {
            let timeString2 = match.string(from: text, atRangeIndex: timeGroup2)
            let time2 = timeString2.firstString ?? ""
            
            if time2 == "早" || time2 == "朝" || time2 == "上" {
                result.start.imply(.hour, to: 6)
            } else if time2 == "下" || time2 == "晏" {
                result.start.imply(.hour, to: 15)
                result.start.imply(.meridiem, to: 1)
            } else if time2 == "中" {
                result.start.imply(.hour, to: 12)
                result.start.imply(.meridiem, to: 1)
            } else if time2 == "夜" || time2 == "晚" {
                result.start.imply(.hour, to: 22)
                result.start.imply(.meridiem, to: 1)
            } else if time2 == "凌" {
                result.start.imply(.hour, to: 0)
            }
            
        } else if match.isNotEmpty(atRangeIndex: dayGroup3) {
            let day3 = match.string(from: text, atRangeIndex: dayGroup3)
            
            if day3 == "明" || day3 == "聽" {
                // Check not "Tomorrow" on late night
                if refMoment.hour > 1 {
                    startMoment = startMoment.added(1, .day)
                }
            } else if day3 == "昨" || day3 == "尋" || day3 == "琴" {
                startMoment = startMoment.added(-1, .day)
            }
            
            if match.isNotEmpty(atRangeIndex: timeGroup3) {
                let timeString3 = match.string(from: text, atRangeIndex: timeGroup3)
                let time3 = timeString3.firstString ?? ""
                
                if time3 == "早" || time3 == "朝" || time3 == "上" {
                    result.start.imply(.hour, to: 6)
                } else if time3 == "下" || time3 == "晏" {
                    result.start.imply(.hour, to: 15)
                    result.start.imply(.meridiem, to: 1)
                } else if time3 == "中" {
                    result.start.imply(.hour, to: 12)
                    result.start.imply(.meridiem, to: 1)
                } else if time3 == "夜" || time3 == "晚" {
                    result.start.imply(.hour, to: 22)
                    result.start.imply(.meridiem, to: 1)
                } else if time3 == "凌" {
                    result.start.imply(.hour, to: 0)
                }
            }
        }
        
        result.start.assign(.day, value: startMoment.day)
        result.start.assign(.month, value: startMoment.month)
        result.start.assign(.year, value: startMoment.year)
        result.tags[.zhHantCasualDateParser] = true
        return result
    }
}
