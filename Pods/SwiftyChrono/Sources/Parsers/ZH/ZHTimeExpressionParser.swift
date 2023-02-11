//
//  ZHTimeExpressionParser.swift
//  SwiftyChrono
//
//  Created by Jerry Chen on 2/18/17.
//  Copyright © 2017 Potix. All rights reserved.
//

import Foundation

private let FIRST_REG_PATTERN = "(?:由|從|自)?" +
    "(?:" +
    "(今|明|聽|昨|尋|琴)(早|朝|晚)|" +
    "(上(?:午|晝)|朝(?:早)|早(?:上)|下(?:午|晝)|晏(?:晝)|晚(?:上)|夜(?:晚)?|中(?:午)|凌(?:晨))|" +
    "(今|明|聽|昨|尋|琴)(?:日|天)" +
    "(?:[\\s,，]*)" +
    "(?:(上(?:午|晝)|朝(?:早)|早(?:上)|下(?:午|晝)|晏(?:晝)|晚(?:上)|夜(?:晚)?|中(?:午)|凌(?:晨)))?" +
    ")?" +
    "(?:[\\s,，]*)" +
    "(?:(\\d+|\(ZH_NUMBER_PATTERN)+)(?:\\s*)(?:點|時|:|：|点|时)" +
    "(?:\\s*)" +
    "(\\d+|半|正|整|\(ZH_NUMBER_PATTERN)+)?(?:\\s*)(?:分|:|：)?" +
    "(?:\\s*)" +
    "(\\d+|\(ZH_NUMBER_PATTERN)+)?(?:\\s*)(?:秒)?)" +
    "(?:\\s*(A\\.M\\.|P\\.M\\.|AM?|PM?))?";

private let SECOND_REG_PATTERN = "(?:\\s*(?:到|至|\\-|\\–|\\~|\\〜)\\s*)" +
    "(?:" +
    "(今|明|聽|昨|尋|琴)(早|朝|晚)|" +
    "(上(?:午|晝)|朝(?:早)|早(?:上)|下(?:午|晝)|晏(?:晝)|晚(?:上)|夜(?:晚)?|中(?:午)|凌(?:晨))|" +
    "(今|明|聽|昨|尋|琴)(?:日|天)" +
    "(?:[\\s,，]*)" +
    "(?:(上(?:午|晝)|朝(?:早)|早(?:上)|下(?:午|晝)|晏(?:晝)|晚(?:上)|夜(?:晚)?|中(?:午)|凌(?:晨)))?" +
    ")?" +
    "(?:[\\s,，]*)" +
    "(?:(\\d+|\(ZH_NUMBER_PATTERN)+)(?:\\s*)(?:點|時|:|：|点|时)" +
    "(?:\\s*)" +
    "(\\d+|半|正|整|\(ZH_NUMBER_PATTERN)+)?(?:\\s*)(?:分|:|：)?" +
    "(?:\\s*)" +
    "(\\d+|\(ZH_NUMBER_PATTERN)+)?(?:\\s*)(?:秒)?)" +
    "(?:\\s*(A\\.M\\.|P\\.M\\.|AM?|PM?))?"

private let dayGroup1 = 1
private let zhAmPmHourGroup1 = 2
private let zhAmPmHourGroup2 = 3
private let dayGroup3 = 4
private let zhAmPmHourGroup3 = 5
private let hourGroup = 6
private let minuteGroup = 7
private let secondGroup = 8
private let amPmHourGroup = 9

public class ZHTimeExpressionParser: Parser {
    override var pattern: String { return FIRST_REG_PATTERN }
    override var language: Language { return .chinese }
    
    override public func extract(text: String, ref: Date, match: NSTextCheckingResult, opt: [OptionType: Int]) -> ParsedResult? {
        // This pattern can be overlaped Ex. [12] AM, 1[2] AM
        let idx = match.range(at: 0).location
        let str = text.substring(from: idx - 1, to: idx)
        if idx > 0 && NSRegularExpression.isMatch(forPattern: "[a-zA-Z0-9_]", in: str) {
            return nil
        }
        
        let refMoment = ref
        var (matchText, index) = matchTextAndIndexForCHHant(from: text, andMatchResult: match)
        var result = ParsedResult(ref: ref, index: index, text: matchText)
        result.tags[.zhHantTimeExpressionParser] = true
        
        var startMoment = refMoment
        
        
        // ----- Day
        if match.isNotEmpty(atRangeIndex: dayGroup1) {
            let day1 = match.string(from: text, atRangeIndex: dayGroup1)
            
            if day1 == "明" || day1 == "聽" {
                // Check not "Tomorrow" on late night
                if refMoment.hour > 1 {
                    startMoment = startMoment.added(1, .day)
                }
            } else if day1 == "昨" || day1 == "尋" || day1 == "琴" {
                startMoment = startMoment.added(-1, .day)
            }
            result.start.assign(.day, value: startMoment.day)
            result.start.assign(.month, value: startMoment.month)
            result.start.assign(.year, value: startMoment.year)
        } else if match.isNotEmpty(atRangeIndex: dayGroup3) {
            let day3 = match.string(from: text, atRangeIndex: dayGroup3)
            if day3 == "明" || day3 == "聽" {
                startMoment = startMoment.added(1, .day)
            } else if day3 == "昨" || day3 == "尋" || day3 == "琴" {
                startMoment = startMoment.added(-1, .day)
            }
            result.start.assign(.day, value: startMoment.day)
            result.start.assign(.month, value: startMoment.month)
            result.start.assign(.year, value: startMoment.year)
        } else {
            result.start.imply(.day, to: startMoment.day)
            result.start.imply(.month, to: startMoment.month)
            result.start.imply(.year, to: startMoment.year)
        }
        
        var hour = 0
        var minute = 0
        var meridiem = -1
        
        // ----- Second
        if match.isNotEmpty(atRangeIndex: secondGroup) {
            let secondString = match.string(from: text, atRangeIndex: secondGroup)
            guard let second = NSRegularExpression.isMatch(forPattern: "\\d+", in: secondString) ? Int(secondString) : ZHStringToNumber(text: secondString) else {
                return nil
            }
            
            if second >= 60 {
                return nil
            }
            result.start.assign(.second, value: second)
        }
        
        var hourString = match.string(from: text, atRangeIndex: hourGroup)
        hour = NSRegularExpression.isMatch(forPattern: "\\d+", in: hourString) ? Int(hourString)! : ZHStringToNumber(text: hourString)
        
        // ----- Minutes
        if match.isNotEmpty(atRangeIndex: minuteGroup) {
            let minuteString = match.string(from: text, atRangeIndex: minuteGroup)
            
            if minuteString == "半" {
                minute = 30;
            } else if minuteString == "正" || minuteString == "整" {
                minute = 0;
            } else {
                minute = NSRegularExpression.isMatch(forPattern: "\\d+", in: minuteString) ? Int(minuteString)! : ZHStringToNumber(text: minuteString)
            }
        } else if hour > 100 {
            minute = hour % 100
            hour =  hour / 100
        }
        
        if minute >= 60 {
            return nil
        }
        
        if hour > 24 {
            return nil
        }
        if hour >= 12 {
            meridiem = 1
        }
        
        // ----- AM & PM
        if match.isNotEmpty(atRangeIndex: amPmHourGroup) {
            if hour > 12 {
                return nil
            }
            
            let ampm = match.string(from: text, atRangeIndex: amPmHourGroup).firstString?.lowercased() ?? ""
            if ampm == "a" {
                meridiem = 0
                if hour == 12 {
                    hour = 0
                }
            }
            
            if ampm == "p" {
                meridiem = 1
                if hour != 12 {
                    hour += 12
                }
            }
        } else if match.isNotEmpty(atRangeIndex: zhAmPmHourGroup1) {
            let zhAMPMString1 = match.string(from: text, atRangeIndex: zhAmPmHourGroup1)
            let zhAMPM1 = zhAMPMString1.firstString ?? ""
            if zhAMPM1 == "朝" || zhAMPM1 == "早" {
                meridiem = 0
                if hour == 12 {
                    hour = 0
                }
            } else if zhAMPM1 == "晚" {
                meridiem = 1
                if hour != 12 {
                    hour += 12
                }
            }
        } else if match.isNotEmpty(atRangeIndex: zhAmPmHourGroup2) {
            let zhAMPMString2 = match.string(from: text, atRangeIndex: zhAmPmHourGroup2)
            let zhAMPM2 = zhAMPMString2.firstString ?? ""
            if zhAMPM2 == "上" || zhAMPM2 == "朝" || zhAMPM2 == "早" || zhAMPM2 == "凌" {
                meridiem = 0
                if hour == 12 {
                    hour = 0
                }
            } else if zhAMPM2 == "下" || zhAMPM2 == "晏" || zhAMPM2 == "晚" {
                meridiem = 1
                if hour != 12 {
                    hour += 12
                }
            }
        } else if match.isNotEmpty(atRangeIndex: zhAmPmHourGroup3) {
            let zhAMPMString3 = match.string(from: text, atRangeIndex: zhAmPmHourGroup3)
            let zhAMPM3 = zhAMPMString3.firstString ?? ""
            if zhAMPM3 == "上" || zhAMPM3 == "朝" || zhAMPM3 == "早" || zhAMPM3 == "凌" {
                meridiem = 0
                if hour == 12 {
                    hour = 0
                }
            } else if zhAMPM3 == "下" || zhAMPM3 == "晏" || zhAMPM3 == "晚" {
                meridiem = 1
                if hour != 12 {
                    hour += 12
                }
            }
        }
        
        result.start.assign(.hour, value: hour)
        result.start.assign(.minute, value: minute)
        
        if meridiem >= 0 {
            result.start.assign(.meridiem, value: meridiem)
        } else {
            if hour < 12 {
                result.start.imply(.meridiem, to: 0)
            } else {
                result.start.imply(.meridiem, to: 1)
            }
        }
        
        // ==============================================================
        //                  Extracting the "to" chunk
        // ==============================================================
        
        let regex = try? NSRegularExpression(pattern: SECOND_REG_PATTERN, options: .caseInsensitive)
        let secondText = text.substring(from: result.index + result.text.count)
        guard let match = regex?.firstMatch(in: secondText, range: NSRange(location: 0, length: secondText.count)) else {
            // Not accept number only result
            if NSRegularExpression.isMatch(forPattern: "^\\d+$", in: result.text) {
                return nil
            }
            
            return result
        }
        matchText = match.string(from: secondText, atRangeIndex: 0)
        
        var endMoment = startMoment
        result.end = ParsedComponents(components: nil, ref: nil)
        
        // ----- Day
        if match.isNotEmpty(atRangeIndex: dayGroup1) {
            let day1 = match.string(from: secondText, atRangeIndex: dayGroup1)
            if day1 == "明" || day1 == "聽" {
                // Check not "Tomorrow" on late night
                if refMoment.hour > 1 {
                    endMoment = endMoment.added(1, .day)
                }
            } else if day1 == "昨" || day1 == "尋" || day1 == "琴" {
                endMoment = endMoment.added(-1, .day)
            }
            
            result.end!.assign(.day, value: endMoment.day)
            result.end!.assign(.month, value: endMoment.month)
            result.end!.assign(.year, value: endMoment.year)
        } else if match.isNotEmpty(atRangeIndex: dayGroup3) {
            let day3 = match.string(from: secondText, atRangeIndex: dayGroup3)
            if day3 == "明" || day3 == "聽" {
                endMoment = endMoment.added(1, .day)
            } else if day3 == "昨" || day3 == "尋" || day3 == "琴" {
                endMoment = endMoment.added(-1, .day)
            }
            result.end!.assign(.day, value: endMoment.day)
            result.end!.assign(.month, value: endMoment.month)
            result.end!.assign(.year, value: endMoment.year)
        } else {
            result.end!.imply(.day, to: endMoment.day)
            result.end!.imply(.month, to: endMoment.month)
            result.end!.imply(.year, to: endMoment.year)
        }
        
        hour = 0
        minute = 0
        meridiem = -1
        
        // ----- Second
        if match.isNotEmpty(atRangeIndex: secondGroup) {
            let secondString = match.string(from: secondText, atRangeIndex: secondGroup)
            let second = NSRegularExpression.isMatch(forPattern: "\\d+", in: secondString) ? Int(secondString)! : ZHStringToNumber(text: secondString)
            
            if second >= 60 {
                return nil
            }
            result.end!.assign(.second, value: second)
        }
        
        hourString = match.string(from: secondText, atRangeIndex: hourGroup)
        hour = NSRegularExpression.isMatch(forPattern: "\\d+", in: hourString) ? Int(hourString)! : ZHStringToNumber(text: hourString)
        
        // ----- Minutes
        if match.isNotEmpty(atRangeIndex: minuteGroup) {
            let minuteString = match.string(from: secondText, atRangeIndex: minuteGroup)
            
            if minuteString == "半" {
                minute = 30
            } else if minuteString == "正" || minuteString == "整" {
                minute = 0
            } else {
                minute = NSRegularExpression.isMatch(forPattern: "\\d+", in: minuteString) ? Int(minuteString)! : ZHStringToNumber(text: minuteString)
            }
        } else if hour > 100 {
            minute = hour % 100;
            hour = hour / 100
        }
        
        if minute >= 60 {
            return nil
        }
        
        if hour > 24 {
            return nil
        }
        if hour >= 12 {
            meridiem = 1
        }
        
        // ----- AM & PM
        if match.isNotEmpty(atRangeIndex: amPmHourGroup) {
            if hour > 12 {
                return nil
            }
            let ampm = match.string(from: secondText, atRangeIndex: amPmHourGroup).firstString?.lowercased() ?? ""
            if ampm == "a" {
                meridiem = 0
                if hour == 12 {
                    hour = 0
                }
            }
            
            if ampm == "p" {
                meridiem = 1
                if hour != 12 {
                    hour += 12
                }
            }
            
            if !result.start.isCertain(component: .meridiem) {
                if meridiem == 0 {
                    result.start.imply(.meridiem, to: 0)
                    
                    if result.start[.hour] == 12 {
                        result.start.assign(.hour, value: 0)
                    }
                    
                } else {
                    result.start.imply(.meridiem, to: 1)
                    
                    if result.start[.hour] != 12 {
                        result.start.assign(.hour, value: result.start[.hour]! + 12)
                    }
                }
            }
            
        } else if match.isNotEmpty(atRangeIndex: zhAmPmHourGroup1) {
            let zhAMPMString1 = match.string(from: secondText, atRangeIndex: zhAmPmHourGroup1)
            let zhAMPM1 = zhAMPMString1.firstString ?? ""
            if zhAMPM1 == "朝" || zhAMPM1 == "早" {
                meridiem = 0
                if hour == 12 {
                    hour = 0
                }
            } else if zhAMPM1 == "晚" {
                meridiem = 1
                if hour != 12 {
                    hour += 12
                }
            }
        } else if match.isNotEmpty(atRangeIndex: zhAmPmHourGroup2) {
            let zhAMPMString2 = match.string(from: secondText, atRangeIndex: zhAmPmHourGroup2)
            let zhAMPM2 = zhAMPMString2.firstString ?? ""
            if zhAMPM2 == "上" || zhAMPM2 == "朝" || zhAMPM2 == "早" || zhAMPM2 == "凌" {
                meridiem = 0
                if hour == 12 {
                    hour = 0
                }
            } else if zhAMPM2 == "下" || zhAMPM2 == "晏" || zhAMPM2 == "晚" {
                meridiem = 1
                if hour != 12 {
                    hour += 12
                }
            }
        } else if match.isNotEmpty(atRangeIndex: zhAmPmHourGroup3) {
            let zhAMPMString3 = match.string(from: secondText, atRangeIndex: zhAmPmHourGroup3)
            let zhAMPM3 = zhAMPMString3.firstString ?? ""
            if zhAMPM3 == "上" || zhAMPM3 == "朝" || zhAMPM3 == "早" || zhAMPM3 == "凌" {
                meridiem = 0
                if hour == 12 {
                    hour = 0
                }
            } else if zhAMPM3 == "下" || zhAMPM3 == "晏" || zhAMPM3 == "晚" {
                meridiem = 1
                if hour != 12 {
                    hour += 12
                }
            }
        }
        
        result.text = result.text + match.string(from: secondText, atRangeIndex: 0)
        result.end!.assign(.hour, value: hour)
        result.end!.assign(.minute, value: minute)
        if meridiem >= 0 {
            result.end!.assign(.meridiem, value: meridiem)
        } else {
            let startAtPM = result.start.isCertain(component: .meridiem) && result.start[.meridiem] == 1
            if startAtPM && result.start[.hour]! > hour {
                // 10pm - 1 (am)
                result.end!.imply(.meridiem, to: 0)
                
            } else if hour > 12 {
                result.end!.imply(.meridiem, to: 1)
            }
        }
        
        if (result.end!.date.timeIntervalSince1970 < result.start.date.timeIntervalSince1970) {
            result.end!.imply(.day, to: result.end![.day]! + 1)
        }
        
        return result;
    }
}
