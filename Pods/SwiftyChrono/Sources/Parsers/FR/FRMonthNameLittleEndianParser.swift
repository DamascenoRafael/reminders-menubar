//
//  FRMonthNameLittleEndianParser.swift
//  SwiftyChrono
//
//  Created by Jerry Chen on 2/6/17.
//  Copyright © 2017 Potix. All rights reserved.
//

import Foundation

private let PATTERN = "(\\W|^)" +
    "(?:(Dimanche|Lundi|Mardi|mercredi|Jeudi|Vendredi|Samedi|Dim|Lun|Mar|Mer|Jeu|Ven|Sam)\\s*,?\\s*)?" +
    "([0-9]{1,2}|1er)" +
    "(?:\\s*(?:au|\\-|\\–|jusqu\'au?|\\s)\\s*([0-9]{1,2})(?:er)?)?\\s*(?:de)?\\s*" +
    "(Jan(?:vier|\\.)?|Fév(?:rier|\\.)?|Mars|Avr(?:il|\\.)?|Mai|Juin|Juil(?:let|\\.)?|Ao[uû]t|Sept(?:embre|\\.)?|Oct(?:obre|\\.)?|Nov(?:embre|\\.)?|déc(?:embre|\\.)?)" +
    "(?:\\s*(\\s*[0-9]{1,4}(?![^\\s]\\d))(?:\\s*(AC|[ap]\\.?\\s*c(?:h(?:r)?)?\\.?\\s*n\\.?))?)?" +
    "(?=\\W|$)"

private let weekdayGroup = 2
private let dateGroup = 3
private let dateToGroup = 4
private let monthNameGroup = 5
private let yearGroup = 6
private let yearBeGroup = 7

public class FRMonthNameLittleEndianParser: Parser {
    override var pattern: String { return PATTERN }
    override var language: Language { return .french }
    
    override public func extract(text: String, ref: Date, match: NSTextCheckingResult, opt: [OptionType: Int]) -> ParsedResult? {
        let (matchText, index) = matchTextAndIndex(from: text, andMatchResult: match)
        var result = ParsedResult(ref: ref, index: index, text: matchText)
        
        let a = match.string(from: text, atRangeIndex: monthNameGroup).lowercased()
        let month = FR_MONTH_OFFSET[a]!
        
        let day = Int(match.string(from: text, atRangeIndex: dateGroup).replacingOccurrences(of: "er", with: ""))!
        
        if match.isNotEmpty(atRangeIndex: yearGroup) {
            var year = Int(match.string(from: text, atRangeIndex: yearGroup).trimmed())!
            
            if match.isNotEmpty(atRangeIndex: yearBeGroup) {
                let yearBe = match.string(from: text, atRangeIndex: yearBeGroup)
                if NSRegularExpression.isMatch(forPattern: "a", in: yearBe) {
                    // Ante Christe natum
                    year = -year
                }
            } else if year < 100 {
                
                year = year + 2000;
            }
            
            result.start.assign(.day, value: day)
            result.start.assign(.month, value: month)
            result.start.assign(.year, value: year)
        } else {
            //Find the most appropriated year
            var refMoment = ref
            refMoment = refMoment.setOrAdded(month, .month)
            refMoment = refMoment.setOrAdded(day, .day)
            refMoment = refMoment.setOrAdded(ref.year, .year)
            
            let nextYear = refMoment.added(1, .year)
            let lastYear = refMoment.added(-1, .year)
            if abs(nextYear.differenceOfTimeInterval(to: ref)) < abs(refMoment.differenceOfTimeInterval(to: ref)) {
                refMoment = nextYear
            } else if abs(lastYear.differenceOfTimeInterval(to: ref)) < abs(refMoment.differenceOfTimeInterval(to: ref)) {
                refMoment = lastYear
            }
            
            result.start.assign(.day, value: day)
            result.start.assign(.month, value: month)
            result.start.imply(.year, to: refMoment.year)
        }
        
        // Weekday component
        if match.isNotEmpty(atRangeIndex: weekdayGroup) {
            let weekday = FR_WEEKDAY_OFFSET[match.string(from: text, atRangeIndex: weekdayGroup).lowercased()]
            result.start.assign(.weekday, value: weekday)
        }
        
        // Text can be 'range' value. Such as '12 - 13 janvier 2012'
        if match.isNotEmpty(atRangeIndex: dateToGroup) {
            result.end = result.start.clone()
            result.end?.assign(.day, value: Int(match.string(from: text, atRangeIndex: dateToGroup))!)
        }
        
        result.tags[.frMonthNameLittleEndianParser] = true
        return result
    }
}



