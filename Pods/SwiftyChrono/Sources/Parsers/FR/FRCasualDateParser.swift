//
//  FRCasualDateParser.swift
//  SwiftyChrono
//
//  Created by Jerry Chen on 2/6/17.
//  Copyright © 2017 Potix. All rights reserved.
//

import Foundation

private let PATTERN = "(\\W|^)(maintenant|aujourd'hui|ajd|cette\\s*nuit|la\\s*veille|(demain|hier)(\\s*(matin|soir|aprem|après-midi))?|ce\\s*(matin|soir)|cet\\s*(après-midi|aprem))(?=\\W|$)"

public class FRCasualDateParser: Parser {
    override var pattern: String { return PATTERN }
    override var language: Language { return .french }
    
    override public func extract(text: String, ref: Date, match: NSTextCheckingResult, opt: [OptionType: Int]) -> ParsedResult? {
        let (matchText, index) = matchTextAndIndex(from: text, andMatchResult: match)
        var result = ParsedResult(ref: ref, index: index, text: matchText)
        
        let refMoment = ref
        var startMoment = refMoment
        let lowerText = matchText.lowercased()
        
        
            
        if NSRegularExpression.isMatch(forPattern: "demain", in: lowerText) {
            // Check not "Tomorrow" on late night
            if refMoment.hour > 1 {
                startMoment = startMoment.added(1, .day)
            }
        }
        
        if NSRegularExpression.isMatch(forPattern: "hier", in: lowerText) {
            startMoment = startMoment.added(-1, .day)
        }
        
        if NSRegularExpression.isMatch(forPattern: "cette\\s*nuit", in: lowerText) {
            // Normally means this coming midnight
            result.start.imply(.hour, to: 22)
            result.start.imply(.meridiem, to: 1)
        } else if NSRegularExpression.isMatch(forPattern: "la\\s*veille", in: lowerText) {
            result.start.imply(.hour, to: 0)
            if refMoment.hour > 6 {
                startMoment = startMoment.added(-1, .day)
            }
        } else if NSRegularExpression.isMatch(forPattern: "(après-midi|aprem)", in: lowerText) {
            result.start.imply(.hour, to: 14)
        } else if NSRegularExpression.isMatch(forPattern: "(soir)", in: lowerText) {
            result.start.imply(.hour, to: 18)
        } else if NSRegularExpression.isMatch(forPattern: "matin", in: lowerText) {
            result.start.imply(.hour, to: 8)
        } else if NSRegularExpression.isMatch(forPattern: "maintenant", in: lowerText) {
            result.start.imply(.hour, to: refMoment.hour)
            result.start.imply(.minute, to: refMoment.minute)
            result.start.imply(.second, to: refMoment.second)
            result.start.imply(.millisecond, to: refMoment.millisecond)
        }
        
        result.start.assign(.day, value: startMoment.day)
        result.start.assign(.month, value: startMoment.month)
        result.start.assign(.year, value: startMoment.year)
        result.tags[.frCasualDateParser] = true
        return result
    }
}

