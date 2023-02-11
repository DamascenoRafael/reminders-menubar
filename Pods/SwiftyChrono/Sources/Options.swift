//
//  Options.swift
//  SwiftyChrono
//
//  Created by Jerry Chen on 1/18/17.
//  Copyright © 2017 Potix. All rights reserved.
//

import Foundation

public struct ModeOptio {
    var parsers: [Parser]
    var refiners: [Refiner]
    
    init(parsers: [Parser], refiners: [Refiner]) {
        self.parsers = parsers
        self.refiners = refiners
    }
}

private func baseOption(strictMode: Bool) -> ModeOptio {
    return ModeOptio(parsers: [
        // EN
        ENISOFormatParser(strictMode: strictMode),
        ENDeadlineFormatParser(strictMode: strictMode),
        ENMonthNameLittleEndianParser(strictMode: strictMode),
        ENMonthNameMiddleEndianParser(strictMode: strictMode),
        ENMonthNameParser(strictMode: strictMode),
        ENSlashDateFormatParser(strictMode: strictMode),
        ENSlashDateFormatStartWithYearParser(strictMode: strictMode),
        ENSlashMonthFormatParser(strictMode: strictMode),
        ENTimeAgoFormatParser(strictMode: strictMode),
        ENTimeExpressionParser(strictMode: strictMode),
        
        // JP
        JPStandardParser(strictMode: strictMode),
        
        // ES
        ESTimeAgoFormatParser(strictMode: strictMode),
        ESDeadlineFormatParser(strictMode: strictMode),
        ESTimeExpressionParser(strictMode: strictMode),
        ESMonthNameLittleEndianParser(strictMode: strictMode),
        ESSlashDateFormatParser(strictMode: strictMode),
        
        // FR
        FRDeadlineFormatParser(strictMode: strictMode),
        FRMonthNameLittleEndianParser(strictMode: strictMode),
        FRSlashDateFormatParser(strictMode: strictMode),
        FRTimeAgoFormatParser(strictMode: strictMode),
        FRTimeExpressionParser(strictMode: strictMode),
        
        // DE
        DEDeadlineFormatParser(strictMode: strictMode),
        DEMonthNameLittleEndianParser(strictMode: strictMode),
        DESlashDateFormatParser(strictMode: strictMode),
        DETimeAgoFormatParser(strictMode: strictMode),
        DETimeExpressionParser(strictMode: strictMode),
        
        // ZH-Hant
        ZHCasualDateParser(strictMode: strictMode),
        ZHDateParser(strictMode: strictMode),
        ZHDeadlineFormatParser(strictMode: strictMode),
        ZHTimeExpressionParser(strictMode: strictMode),
        ZHWeekdayParser(strictMode: strictMode),
        
    ], refiners: [
        // Removing overlaping first
        OverlapRemovalRefiner(),
        ForwardDateRefiner(),
        
        // ETC
        ENMergeDateTimeRefiner(),
        ENMergeDateRangeRefiner(),
        ENPrioritizeSpecificDateRefiner(),
        FRMergeDateRangeRefiner(),
        FRMergeDateTimeRefiner(),
        JPMergeDateRangeRefiner(),
        DEMergeDateTimeRefiner(),
        DEMergeDateRangeRefiner(),
        
        // Extract additional info later
        ExtractTimezoneOffsetRefiner(),
        ExtractTimezoneAbbrRefiner(),
        
        UnlikelyFormatFilter(),
    ])
}

func strictModeOption() -> ModeOptio {
    return baseOption(strictMode: true)
}

public func casualModeOption() -> ModeOptio {
    var options = baseOption(strictMode: false)
    
    options.parsers.insert(contentsOf: [
        // EN
        ENCasualTimeParser(strictMode: false),
        ENCasualDateParser(strictMode: false),
        ENWeekdayParser(strictMode: false),
        ENRelativeDateFormatParser(strictMode: false),
        
        // JP
        JPCasualDateParser(strictMode: false),
        
        // ES
        ESCasualDateParser(strictMode: false),
        ESWeekdayParser(strictMode: false),
        
        // FR
        FRCasualDateParser(strictMode: false),
        FRWeekdayParser(strictMode: false),
        
        // DE
        DECasualTimeParser(strictMode: false),
        DECasualDateParser(strictMode: false),
        DEWeekdayParser(strictMode: false),
        DEMorgenTimeParser(strictMode: false),
        
    ], at: 0)
    
    return options
}

public enum Language {
    case english, spanish, french, japanese, german, chinese
}
