//
//  ESMonthNameLittleEndianParser.swift
//  SwiftyChrono
//
//  Created by Jerry Chen on 2/6/17.
//  Copyright © 2017 Potix. All rights reserved.
//

import Foundation

private let PATTERN = "(\\W|^)" +
    "(?:(Domingo|Lunes|Martes|Miércoles|Miercoles|Jueves|Viernes|Sábado|Sabado|Dom|Lun|Mar|Mie|Jue|Vie|Sab)\\s*,?\\s*)?" +
    "([0-9]{1,2})(?:º|ª|°)?" +
    "(?:\\s*(?:desde|de|\\-|\\–|al?|hasta|\\s)\\s*([0-9]{1,2})(?:º|ª|°)?)?\\s*(?:de)?\\s*" +
    "(Ene(?:ro|\\.)?|Feb(?:rero|\\.)?|Mar(?:zo|\\.)?|Abr(?:il|\\.)?|May(?:o|\\.)?|Jun(?:io|\\.)?|Jul(?:io|\\.)?|Ago(?:sto|\\.)?|Sep(?:tiembre|\\.)?|Oct(?:ubre|\\.)?|Nov(?:iembre|\\.)?|Dic(?:iembre|\\.)?)" +
    "(?:\\s*(?:del?)?(\\s*[0-9]{1,4}(?![^\\s]\\d))(\\s*[ad]\\.?\\s*c\\.?|a\\.?\\s*d\\.?)?)?" +
    "(?=\\W|$)"

private let weekdayGroup = 2
private let dateGroup = 3
private let dateToGroup = 4
private let monthNameGroup = 5
private let yearGroup = 6
private let yearBeGroup = 7

public class ESMonthNameLittleEndianParser: Parser {
    override var pattern: String { return PATTERN }
    override var language: Language { return .spanish }
    
    override public func extract(text: String, ref: Date, match: NSTextCheckingResult, opt: [OptionType: Int]) -> ParsedResult? {
        let (matchText, index) = matchTextAndIndex(from: text, andMatchResult: match)
        var result = ParsedResult(ref: ref, index: index, text: matchText)
        
        let month = ES_MONTH_OFFSET[match.string(from: text, atRangeIndex: monthNameGroup).lowercased()]!
        
        let day = Int(match.string(from: text, atRangeIndex: dateGroup))!
        
        if match.isNotEmpty(atRangeIndex: yearGroup) {
            var year = Int(match.string(from: text, atRangeIndex: yearGroup).trimmed())!
            
            if match.isNotEmpty(atRangeIndex: yearBeGroup) {
                let yearBe = match.string(from: text, atRangeIndex: yearBeGroup)
                if NSRegularExpression.isMatch(forPattern: "a\\.?\\s*c\\.?", in: yearBe) {
                    // antes de Cristo
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
            let weekday = ES_WEEKDAY_OFFSET[match.string(from: text, atRangeIndex: weekdayGroup).lowercased()]
            result.start.assign(.weekday, value: weekday)
        }
        
        // Text can be 'range' value. Such as '12 - 13 January 2012'
        if match.isNotEmpty(atRangeIndex: dateToGroup) {
            result.end = result.start.clone()
            result.end?.assign(.day, value: Int(match.string(from: text, atRangeIndex: dateToGroup))!)
        }
        
        result.tags[.esMonthNameLittleEndianParser] = true
        return result
    }
}


