//
//  Result.swift
//  SwiftyChrono
//
//  Created by Jerry Chen on 1/17/17.
//  Copyright © 2017 Potix. All rights reserved.
//

import Foundation

public struct ParsedResult {
    public let ref: Date
    public var index: Int
    public var text: String
    public var tags: [TagUnit: Bool]
    public var start: ParsedComponents
    public var end: ParsedComponents?
    
    // used for parsing logic controll
    public let isMoveIndexMode: Bool
    
    public init(ref: Date, index: Int, text: String, tags: [TagUnit: Bool] = [TagUnit: Bool](), start: [ComponentUnit: Int]? = nil, end: [ComponentUnit: Int]? = nil, isMoveIndexMode: Bool = false) {
        self.ref = ref
        self.index = index
        self.text = text
        self.tags = tags
        self.start = ParsedComponents(components: start, ref: ref)
        if let end = end {
            self.end = ParsedComponents(components: end, ref: ref)
        }
        self.isMoveIndexMode = isMoveIndexMode
    }
    
    static func moveIndexMode(index: Int) -> ParsedResult {
        return self.init(ref: Date(), index: index, text: "", isMoveIndexMode: true)
    }
    
    func clone() -> ParsedResult {
        var result = ParsedResult(ref: ref, index: index, text: text, tags: tags)
        
        result.start = start
        result.end = end
        
        return result
    }
    
    func hasPossibleDates() -> Bool {
        return start.isPossibleDate() && (end == nil || end!.isPossibleDate())
    }
}

public struct ParsedComponents {
    public var knownValues = [ComponentUnit: Int]()
    public var impliedValues = [ComponentUnit: Int]()
    
    init(components: [ComponentUnit: Int]?, ref: Date?) {
        if let components = components {
            knownValues = components
        }
        
        if let ref = ref {
            imply(.day, to: ref.day)
            imply(.month, to: ref.month)
            imply(.year, to: ref.year)
        }
        
        imply(.hour, to: Chrono.defaultImpliedHour)
        imply(.minute, to: Chrono.defaultImpliedMinute)
        imply(.second, to: Chrono.defaultImpliedSecond)
        imply(.millisecond, to: Chrono.defaultImpliedMillisecond)
    }
    
    private init(parsedComponents: ParsedComponents) {
        knownValues = parsedComponents.knownValues
        impliedValues = parsedComponents.impliedValues
    }
    
    public func clone() -> ParsedComponents {
        return ParsedComponents(parsedComponents: self)
    }
    
    public subscript(component: ComponentUnit) -> Int? {
        if knownValues.keys.contains(component) { return knownValues[component]! }
        if impliedValues.keys.contains(component) { return impliedValues[component]! }
        
        return nil
    }
    
    public mutating func assign(_ component: ComponentUnit, value: Int?) {
        if let value = value {
            knownValues[component] = value
            impliedValues.removeValue(forKey: component)
        }
    }
    
    public mutating func imply(_ component: ComponentUnit, to value: Int?) {
        guard let value = value else {
            return
        }
        if knownValues.keys.contains(component) { return }
        impliedValues[component] = value
    }
    
    public func isCertain(component: ComponentUnit) -> Bool {
        return knownValues.keys.contains(component)
    }
    
    public func isPossibleDate() -> Bool {
        var date = moment
        var isUTC = false
        if isCertain(component: .timeZoneOffset) {
            // iOS only: in moment.js lib, set utcOffset will turn on isUTC, so the getter will count on utc based time zone
            isUTC = true
            date.utcOffset = self[.timeZoneOffset]!
        }
        
        if (isUTC ? date.utcYear : date.year) != self[.year] { return false }
        if (isUTC ? date.utcMonth : date.month) != self[.month] { return false }
        if (isUTC ? date.utcDay : date.day) != self[.day] { return false }
        if (isUTC ? date.utcHour : date.hour) != self[.hour] { return false }
        if (isUTC ? date.utcMinute : date.minute) != self[.minute] { return false }
        
        return true
    }
    
    public var date: Date {
        return moment
    }
    
    public var moment: Date {
        var comps = DateComponents()
        
        if let year = self[.year] {
            comps.year = year
        }
        
        if let month = self[.month] {
            comps.month = month
        }
        
        if let day = self[.day] {
            comps.day = day
        }
        
        if let hour = self[.hour] {
            comps.hour = hour
        }
        
        if let minute = self[.minute] {
            comps.minute = minute
        }
        
        if let second = self[.second] {
            comps.second = second
        }
        
        if let millisecond = self[.millisecond] {
            comps.nanosecond = millisecondsToNanoSeconds(millisecond)
        }
        
        let date = cal.date(from: comps)!
        
        let currenttimeZoneOffset = date.utcOffset
        let targettimeZoneOffset =
            isCertain(component: .timeZoneOffset) ? self[.timeZoneOffset]! : currenttimeZoneOffset
        
        let adjustedtimeZoneOffset = targettimeZoneOffset - currenttimeZoneOffset
        let newDate = date.added(-adjustedtimeZoneOffset, .minute)
        
        if Chrono.sixMinutesFixBefore1900 && newDate.utcYear < 1900 {
            return newDate.added(6, .minute)
        }
        
        return newDate
    }
}

public enum ComponentUnit {
    case year, month, day, hour, minute, second, millisecond, weekday, timeZoneOffset, meridiem
}

public enum TagUnit { case
    none,
    enCasualTimeParser,
    enCasualDateParser,
    enDeadlineFormatParser,
    enISOFormatParser,
    enMonthNameLittleEndianParser,
    enMonthNameMiddleEndianParser,
    enMonthNameParser,
    enRelativeDateFormatParser,
    enSlashDateFormatParser,
    enSlashDateFormatStartWithYearParser,
    enSlashMonthFormatParser,
    enTimeAgoFormatParser,
    enTimeExpressionParser,
    enWeekdayParser,
    
    esCasualDateParser,
    esDeadlineFormatParser,
    esMonthNameLittleEndianParser,
    esSlashDateFormatParser,
    esTimeAgoFormatParser,
    esTimeExpressionParser,
    esWeekdayParser,
    
    frCasualDateParser,
    frDeadlineFormatParser,
    frMonthNameLittleEndianParser,
    frSlashDateFormatParser,
    frTimeAgoFormatParser,
    frTimeExpressionParser,
    frWeekdayParser,
    
    jpCasualDateParser,
    jpStandardParser,
    
    deCasualTimeParser,
    deCasualDateParser,
    deDeadlineFormatParser,
    deMonthNameLittleEndianParser,
    deSlashDateFormatParser,
    deTimeAgoFormatParser,
    deTimeExpressionParser,
    deWeekdayParser,
    deMorgenTimeParser,
    
    zhHantCasualDateParser,
    zhHantDateParser,
    zhHantDeadlineFormatParser,
    zhHantTimeExpressionParser,
    zhHantWeekdayParser,
    
    extractTimezoneAbbrRefiner,
    extractTimezoneOffsetRefiner,
    forwardDateRefiner,
    
    enMergeDateAndTimeRefiner,
    enMergeDateRangeRefiner,
    enPrioritizeSpecificDateRefiner,
    
    frMergeDateRangeRefiner,
    frMergeDateAndTimeRefiner,
    
    deMergeDateAndTimeRefiner,
    deMergeDateRangeRefiner
}











