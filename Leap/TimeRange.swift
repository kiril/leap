//
//  TimeRange.swift
//  Leap
//
//  Created by Chris Ricca on 4/20/17. 🍁
//  Copyright © 2017 Single Leap, Inc. All rights reserved.
//

import Foundation

struct TimeRange: TimeRangeExcludable {
    let start: Date
    let end: Date

    var durationInSeconds: TimeInterval {
        return end.timeIntervalSinceReferenceDate - start.timeIntervalSinceReferenceDate
    }

    init?(start: Date, end: Date) {
        guard start.timeIntervalSinceReferenceDate < end.timeIntervalSinceReferenceDate else { return nil }
        self.start = start
        self.end = end
    }

    func timeRangesByExcluding(timeRange: TimeRange) -> [TimeRange] {
        if  timeRange.end.timeIntervalSinceReferenceDate <= start.timeIntervalSinceReferenceDate ||
            timeRange.start.timeIntervalSinceReferenceDate >= end.timeIntervalSinceReferenceDate {
            // no intersection at all
            return [self]
        } else {
            let a = TimeRange(start: start,
                              end: timeRange.start)
            let b = TimeRange(start: timeRange.end,
                              end: end)
            return [a,b].flatMap() { $0 } // flatMap removes nil values
            // this will return 0,1, or 2 ranges, depending on how many valid ranges remain after the intersection
        }
    }

    func isWithin(timeRange: TimeRange) -> Bool {
        return  (start >= timeRange.start) &&
                (end <= timeRange.end)
    }

    static func of(day: GregorianDay) -> TimeRange {
        return TimeRange(start: Calendar.current.startOfDay(for: day), end: Calendar.current.startOfDay(for: day.dayAfter))!
    }
}

protocol TimeRangeExcludable {
    func timeRangesByExcluding(timeRange: TimeRange) -> [TimeRange]
}

extension Array where Element: TimeRangeExcludable {
    func timeRangesByExcluding(timeRange: TimeRange) -> [TimeRange] {
        let a = self as! [TimeRange] // better way to explain this to compiler?
        return a.flatMap() { $0.timeRangesByExcluding(timeRange: timeRange) }
    }

    var combinedDurationInSeconds: TimeInterval {
        return (self as! [TimeRange]).reduce((0 as TimeInterval)) { (result: TimeInterval, range) -> TimeInterval in
            return result + range.durationInSeconds
        }
    }
}
