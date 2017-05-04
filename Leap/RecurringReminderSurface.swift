//
//  RecurringReminderSurface.swift
//  Leap
//
//  Created by Kiril Savino on 5/4/17.
//  Copyright © 2017 Single Leap, Inc. All rights reserved.
//

import Foundation

class RecurringReminderSurface: ReminderSurface {

    static func timeRange(template: Template, in range: TimeRange) -> String {
        let calendar = Calendar.current
        let startHour = calendar.component(.hour, from: range.start)
        let endHour = calendar.component(.hour, from: range.end)

        let spansDays = calendar.areOnDifferentDays(range.start, range.end)
        let crossesNoon = spansDays || ( startHour < 12 && endHour >= 12 )

        let from = calendar.formatDisplayTime(from: range.start, needsAMPM: crossesNoon)
        let to = calendar.formatDisplayTime(from: range.end, needsAMPM: true)
        var more = ""
        if spansDays {
            let days = calendar.daysBetween(range.start, and: range.end)
            let ess = days == 1 ? "" : "s"
            more = " \(days) day\(ess) later"
        }

        return "\(from) - \(to)\(more)"
    }

    static func load(from series: Series, in range: TimeRange) -> ReminderSurface? {
        let surface = RecurringReminderSurface(id: series.id)
        let bridge = SurfaceModelBridge(id: series.id, surface: surface)

        bridge.reference(series, as: "series")

        bridge.bind(surface.title)
        bridge.readonlyBind(surface.startTime) { ($0 as! Series).template.startTime(in: range) }
        bridge.readonlyBind(surface.endTime) { ($0 as! Series).template.endTime(in: range) }
        bridge.readonlyBind(surface.refersToEvent) { (model:LeapModel) in return true }
        bridge.readonlyBind(surface.eventTime) { ($0 as! Series).referencing!.template.startTime(in: range) }
        bridge.readonlyBind(surface.timeRange) { timeRange(template: ($0 as! Series).referencing!.template, in: range) }
        bridge.readonlyBind(surface.reminderType) { ($0 as! Series).template.reminderType }

        surface.store = bridge
        bridge.populate(surface, with: series, as: "series")
        return surface
    }
}
