//
//  ExtractTimezoneOffsetRefiner.swift
//  SwiftyChrono
//
//  Created by Jerry Chen on 1/24/17.
//  Copyright © 2017 Potix. All rights reserved.
//

import Foundation

private let PATTERN = "^\\s*(GMT|UTC)?(\\+|\\-)(\\d{1,2}):?(\\d{2})"

private let timezoneOffsetSignGroup = 2
private let timezoneOffsetHourOffset = 3
private let timezoneOffsetMinuteOffsetGroup = 4

class ExtractTimezoneOffsetRefiner: Refiner {
    override public func refine(text: String, results: [ParsedResult], opt: [OptionType: Int]) -> [ParsedResult] {
        let resultsLength = results.count
        var newResults = [ParsedResult]()
        
        var i = 0
        while i < resultsLength {
            var result = results[i]
            
            if result.start.isCertain(component: .timeZoneOffset) {
                newResults.append(result)
                i += 1
                continue
            }
            
            let substring = text.substring(from: result.index + result.text.count)
            guard
                let regex = (try? NSRegularExpression(pattern: PATTERN, options: .caseInsensitive)),
                let match = regex.firstMatch(in: substring, range: NSRange(location: 0, length: substring.count))
            else {
                i += 1
                newResults.append(result)
                continue
            }
            
            let hourOffset = Int(match.string(from: substring, atRangeIndex: timezoneOffsetHourOffset))!
            let minuteOffset = Int(match.string(from: substring, atRangeIndex: timezoneOffsetMinuteOffsetGroup))!
            var timezoneOffset = hourOffset * 60 + minuteOffset
            
            if match.string(from: substring, atRangeIndex: timezoneOffsetSignGroup) == "-" {
                timezoneOffset = -timezoneOffset
            }
            
            if result.end != nil {
                result.end!.assign(.timeZoneOffset, value: timezoneOffset)
            }
            
            result.start.assign(.timeZoneOffset, value: timezoneOffset)
            result.text += match.string(from: substring, atRangeIndex: 0)
            result.tags[.extractTimezoneOffsetRefiner] = true
            
            i += 1
            newResults.append(result)
        }
        
        return newResults
    }
}
