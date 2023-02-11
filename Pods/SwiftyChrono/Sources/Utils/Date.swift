//
//  Date.swift
//  SwiftyChrono
//
//  Created by Jerry Chen on 1/17/17.
//  Copyright © 2017 Potix. All rights reserved.
//

import Foundation

var cal: Calendar { return Calendar.current }
var utcCal: Calendar {
    var cal = Calendar(identifier: Calendar.Identifier.gregorian)
    cal.timeZone = utcTimeZone
    return cal
}
let utcTimeZone: TimeZone = TimeZone(identifier: "UTC")!

private let noneZeroComponents: Set<Calendar.Component> = [.year, .month, .day]

extension Date {
    func setOrAdded(_ value: Int, _ component: Calendar.Component) -> Date {
        let d = self
        var value = value
        
        switch component {
        case .year:
            value -= d.year
        case .month:
            value -= d.month
        case .day:
            value -= d.day
        case .hour:
            value -= d.hour
        case .minute:
            value -= d.minute
        case .second:
            value -= d.second
        case .nanosecond:
            value -= d.nanosecond
        case .weekday:
            value -= d.weekday
        default:
            assert(false, "unsupported component...")
        }
        return d.added(value, component)
    }
    
    func isAfter(_ other: Date) -> Bool {
        return self.timeIntervalSince1970 > other.timeIntervalSince1970
    }
    
    var year: Int { return cal.component(.year, from: self) }
    var month: Int { return cal.component(.month, from: self) }
    var day: Int { return cal.component(.day, from: self) }
    var hour: Int { return cal.component(.hour, from: self) }
    var minute: Int { return cal.component(.minute, from: self) }
    var second: Int { return cal.component(.second, from: self) }
    var millisecond: Int { return nanoSecondsToMilliseconds(cal.component(.nanosecond, from: self)) }
    var nanosecond: Int { return cal.component(.nanosecond, from: self) }
    var weekday: Int {
        // by default, start from 1. we mimic the moment.js' SPEC, start from 0
        return cal.component(.weekday, from: self) - 1
    }
    
    var utcYear: Int { return utcCal.component(.year, from: self) }
    var utcMonth: Int { return utcCal.component(.month, from: self) }
    var utcDay: Int { return utcCal.component(.day, from: self) }
    var utcHour: Int { return utcCal.component(.hour, from: self) }
    var utcMinute: Int { return utcCal.component(.minute, from: self) }
    var utcSecond: Int { return utcCal.component(.second, from: self) }
    var utcMillisecond: Int { return nanoSecondsToMilliseconds(utcCal.component(.nanosecond, from: self)) }
    var utcNanosecond: Int { return utcCal.component(.nanosecond, from: self) }
    var utcWeekday: Int {
        // by default, start from 1. we mimic the moment.js' SPEC, start from 0
        return utcCal.component(.weekday, from: self) - 1
    }
    
    /// ask number of day in the current month.
    ///
    /// e.g. the "unit" will be .day, the "baseUnit" will be .month
    func numberOf(_ unit: Calendar.Component, inA baseUnit: Calendar.Component) -> Int? {
        if let range = cal.range(of: unit, in: baseUnit, for: self) {
            return range.upperBound - range.lowerBound
        }
        
        return nil
    }
    
    func differenceOfTimeInterval(to date: Date) -> TimeInterval {
        return timeIntervalSince1970 - date.timeIntervalSince1970
    }
    
    /// offset minutes between UTC and current time zone, the value could be 60, 0, -60, etc.
    var utcOffset: Int {
        get {
            let timeZone = NSTimeZone.local
            let offsetSeconds = timeZone.secondsFromGMT(for: self)
            return offsetSeconds / 60
        }
        set {
            let interval = TimeInterval(newValue * 60)
            self = Date(timeInterval: interval, since: self)
        }
    }
    
    func added(_ value: Int, _ unit: Calendar.Component) -> Date {
        return cal.date(byAdding: unit, value: value, to: self)!
    }
}

func millisecondsToNanoSeconds(_ milliseconds: Int) -> Int {
    return milliseconds * 1000000
}

func nanoSecondsToMilliseconds(_ nanoSeconds: Int) -> Int {
    /// this convert is used to prevent from nanoseconds error
    /// test case, create a date with nanoseconds 11000000, and get it via Calendar.Component, you will get 10999998
    let doubleMs = Double(nanoSeconds) / 1000000
    let ms = Int(doubleMs)
    return doubleMs > Double(ms) ? ms + 1 : ms
}
