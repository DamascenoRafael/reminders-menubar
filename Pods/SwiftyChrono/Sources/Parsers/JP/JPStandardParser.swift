//
//  JPStandardParser.swift
//  SwiftyChrono
//
//  Created by Jerry Chen on 2/6/17.
//  Copyright © 2017 Potix. All rights reserved.
//

import Foundation

private let PATTERN = "(?:(同|((昭和|平成)?([0-9０-９]{2,4})))年\\s*)?([0-9０-９]{1,2})月\\s*([0-9０-９]{1,2})日"

private let yearGroup = 2
private let eraGroup = 3
private let yearNumberGroup = 4
private let monthGroup = 5
private let dayGroup = 6

public class JPStandardParser: Parser {
    override var pattern: String { return PATTERN }
    override var language: Language { return .japanese }
    
    override public func extract(text: String, ref: Date, match: NSTextCheckingResult, opt: [OptionType: Int]) -> ParsedResult? {
        let index = match.range(at: 0).location
        let matchText = match.string(from: text, atRangeIndex: 0)
        
        var startMoment = ref
        var result = ParsedResult(ref: ref, index: index, text: matchText)
        
        let month = Int(match.string(from: text, atRangeIndex: monthGroup).hankakuOnlyNumber)!
        
        let day = Int(match.string(from: text, atRangeIndex: dayGroup).hankakuOnlyNumber)!
        
        
        startMoment = startMoment
            .setOrAdded(day, .day)
            .setOrAdded(month, .month)
        
        result.start.assign(.day, value: startMoment.day)
        result.start.assign(.month, value: startMoment.month)
        
        
        if match.isEmpty(atRangeIndex: yearGroup) {
            
            //Find the most appropriated year
            startMoment = startMoment.setOrAdded(ref.year, .year)
            let nextYear = startMoment.added(1, .year)
            let lastYear = startMoment.added(-1, .year)
            
            if abs(nextYear.differenceOfTimeInterval(to: ref)) < abs(startMoment.differenceOfTimeInterval(to: ref)) {
                startMoment = nextYear
            } else if abs(lastYear.differenceOfTimeInterval(to: ref)) < abs(startMoment.differenceOfTimeInterval(to: ref)) {
                startMoment = lastYear
            }
            
            result.start.assign(.day, value: startMoment.day)
            result.start.assign(.month, value: startMoment.month)
            result.start.imply(.year, to: startMoment.year)
        } else if NSRegularExpression.isMatch(forPattern: "同年", in: text) {
            result.start.assign(.year, value: startMoment.year)
        } else {
            var year = Int(match.string(from: text, atRangeIndex: yearNumberGroup).hankakuOnlyNumber)!
            if match.isNotEmpty(atRangeIndex: eraGroup) {
                let era = match.string(from: text, atRangeIndex: eraGroup)
                if era == "平成" {
                    year += 1988
                } else if era == "昭和" {
                    year += 1925
                }
            }
            
            result.start.assign(.year, value: year)
        }
        
        result.tags[.jpStandardParser] = true
        return result
    }
}



