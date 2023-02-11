//
//  ESCasualDateParser.swift
//  SwiftyChrono
//
//  Created by Jerry Chen on 2/6/17.
//  Copyright © 2017 Potix. All rights reserved.
//

import Foundation

/*
 Valid patterns:
 - esta mañana -> today in the morning
 - esta tarde -> today in the afternoon/evening
 - esta noche -> tonight
 - ayer por la mañana -> yesterday in the morning
 - ayer por la tarde -> yesterday in the afternoon/evening
 - ayer por la noche -> yesterday at night
 - mañana por la mañana -> tomorrow in the morning
 - mañana por la tarde -> tomorrow in the afternoon/evening
 - mañana por la noche -> tomorrow at night
 - anoche -> tomorrow at night
 - hoy -> today
 - ayer -> yesterday
 - mañana -> tomorrow
 */
private let PATTERN = "(\\W|^)(ahora|esta\\s*(mañana|tarde|noche)|(ayer|mañana)\\s*por\\s*la\\s*(mañana|tarde|noche)|hoy|mañana|ayer|anoche)(?=\\W|$)"

public class ESCasualDateParser: Parser {
    override var pattern: String { return PATTERN }
    override var language: Language { return .spanish }
    
    override public func extract(text: String, ref: Date, match: NSTextCheckingResult, opt: [OptionType: Int]) -> ParsedResult? {
        let (matchText, index) = matchTextAndIndex(from: text, andMatchResult: match)
        var result = ParsedResult(ref: ref, index: index, text: matchText)
        
        let refMoment = ref
        var startMoment = refMoment
        let regex = try! NSRegularExpression(pattern: "\\s+")
        let lowerText = regex.stringByReplacingMatches(in: matchText.lowercased(), range: NSRange(location: 0, length: matchText.count), withTemplate: " ")
        
        if lowerText == "mañana" {
            // Check not "Tomorrow" on late night
            if ref.hour > 1 {
                startMoment = startMoment.added(1, .day)
            }
            
        } else if lowerText == "ayer" {
            
            startMoment = startMoment.added(-1, .day)
            
        } else if lowerText == "anoche" {
            result.start.imply(.hour, to: 0)
            if refMoment.hour > 6 {
                startMoment = startMoment.added(-1, .day)
            }

        } else if NSRegularExpression.isMatch(forPattern: "esta", in: lowerText) {
            
            let secondMatch = match.string(from: text, atRangeIndex: 3).lowercased()
            if secondMatch == "tarde" {
                result.start.imply(.hour, to: 18)
                
            } else if secondMatch == "mañana" {
                result.start.imply(.hour, to: 6)
                
            } else if (secondMatch == "noche") {
                
                // Normally means this coming midnight
                result.start.imply(.hour, to: 22)
                result.start.imply(.meridiem, to: 1)
                
            }
        
        } else if NSRegularExpression.isMatch(forPattern: "por\\s*la", in: lowerText) {
            let firstMatch = match.string(from: text, atRangeIndex: 4).lowercased()
            if firstMatch == "ayer" {
                startMoment = startMoment.added(-1, .day)
                
            } else if firstMatch == "mañana" {
                startMoment = startMoment.added(1, .day)
                
            }
            
            
            let secondMatch = match.string(from: text, atRangeIndex: 5).lowercased()
            if secondMatch == "tarde" {
                result.start.imply(.hour, to: 18)
                
            } else if secondMatch == "mañana" {
                result.start.imply(.hour, to: 9)
                
            } else if secondMatch == "noche" {
                
                // Normally means this coming midnight
                result.start.imply(.hour, to: 22)
                result.start.imply(.meridiem, to: 1)
                
            }
            
        } else if NSRegularExpression.isMatch(forPattern: "ahora", in: lowerText) {
            
            result.start.imply(.hour, to: refMoment.hour)
            result.start.imply(.minute, to: refMoment.minute)
            result.start.imply(.second, to: refMoment.second)
            result.start.imply(.millisecond, to: refMoment.millisecond)
            
        }
        
        result.start.assign(.day, value: startMoment.day)
        result.start.assign(.month, value: startMoment.month)
        result.start.assign(.year, value: startMoment.year)
        result.tags[.esCasualDateParser] = true
        return result
    }
}
