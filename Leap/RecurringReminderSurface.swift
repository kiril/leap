//
//  RecurringReminderSurface.swift
//  Leap
//
//  Created by Kiril Savino on 5/4/17.
//  Copyright © 2017 Single Leap, Inc. All rights reserved.
//

import Foundation

class RecurringReminderSurface: ReminderSurface {

    var range: TimeRange!

    static func load(from series: Series, in range: TimeRange) -> ReminderSurface? {
        var startRange = range
        if !series.recurs(in: range) {
            guard series.recurs(overlapping: range) else { return nil }
            startRange = series.extend(range: range)
        }
        let surface = RecurringReminderSurface(id: series.id)
        surface.range = range
        let bridge = SurfaceModelBridge(id: series.id, surface: surface)

        bridge.reference(series, as: "series")

        bridge.bind(surface.title)
        bridge.readonlyBind(surface.startTime) { ($0 as! Series).startTime(in: startRange)!.secondsSinceReferenceDate }
        bridge.readonlyBind(surface.endTime) { ($0 as! Series).endTime(in: startRange)?.secondsSinceReferenceDate ?? 0 }
        bridge.readonlyBind(surface.refersToEvent) { (model:LeapModel) in return true }
        bridge.readonlyBind(surface.reminderType) { ($0 as! Series).template.reminderType }
        bridge.readonlyBind(surface.eventId) { ($0 as! Series).referencing?.id }

        surface.store = bridge
        bridge.populate(surface, with: series, as: "series")
        return surface
    }

    override func formatEventDuration(viewedFrom day: GregorianDay? = nil) -> String? {
        guard let series = Series.by(id: self.id), let other = series.referencing else { return nil }

        let fullRange = other.extend(range: range)

        guard let time = other.template.range(in: fullRange) else { return nil }

        let enclosing = day != nil ? TimeRange.of(day: day!) : range!

        let calendar = Calendar.current
        let startHour = calendar.component(.hour, from: time.start)
        let endHour = calendar.component(.hour, from: time.end)

        let spansDays = calendar.areOnDifferentDays(time.start, time.end)
        let crossesNoon = spansDays || ( startHour < 12 && endHour >= 12 )

        let from = calendar.formatDisplayTime(from: time.start, needsAMPM: crossesNoon)
        let to = calendar.formatDisplayTime(from: time.end, needsAMPM: true)
        var after = ""
        var before = ""
        if spansDays {
            if time.start < enclosing.start {
                let daysEarlier = calendar.daysBetween(time.start, and: enclosing.start)
                switch daysEarlier {
                case 0, 1:
                    before = "(Yesterday) "
                default:
                    before = "(\(daysEarlier) days ago) "
                }
            }

            if time.end > enclosing.end {
                let daysLater = calendar.daysBetween(time.end, and: enclosing.end)
                switch daysLater {
                case 0, 1:
                    after = " (Tomorrow)"
                default:
                    after = " (in \(daysLater) days)"
                }
            } else if time.start < enclosing.start {
                after = " today"
            }
        }
        
        return "\(before)\(from) - \(to)\(after)"
    }
}
