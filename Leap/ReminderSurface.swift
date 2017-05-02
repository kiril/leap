//
//  ReminderSurface.swift
//  Leap
//
//  Created by Chris Ricca on 4/24/17.
//  Copyright © 2017 Single Leap, Inc. All rights reserved.
//

import Foundation
import IGListKit

class ReminderSurface: Surface, ModelLoadable {
    override var type: String { return "reminder" }

    let title                  = SurfaceString(minLength: 1)
    let startTime              = SurfaceInt()
    let endTime                = SurfaceInt()
    let refersToEvent          = SurfaceBool()
    let eventTime              = SurfaceString()
    let timeRange              = SurfaceString()
    let reminderType           = SurfaceProperty<ReminderType>()


    static func timeRange(event: Event) -> String {
        let start = event.startDate
        let end = event.endDate

        let calendar = Calendar.current
        let startHour = calendar.component(.hour, from: start)
        let endHour = calendar.component(.hour, from: end)

        let spansDays = calendar.areOnDifferentDays(start, end)
        let crossesNoon = spansDays || ( startHour < 12 && endHour >= 12 )

        let from = calendar.formatDisplayTime(from: start, needsAMPM: crossesNoon)
        let to = calendar.formatDisplayTime(from: end, needsAMPM: true)
        var more = ""
        if spansDays {
            let days = calendar.daysBetween(start, and: end)
            let ess = days == 1 ? "" : "s"
            more = " \(days) day\(ess) later"
        }

        return "\(from) - \(to)\(more)"
    }

    static func timeRange(reminder: Reminder) -> String? {
        let start = reminder.startDate
        guard let end = reminder.endDate else {
            return nil
        }

        let calendar = Calendar.current
        let startHour = calendar.component(.hour, from: start)
        let endHour = calendar.component(.hour, from: end)

        let spansDays = calendar.areOnDifferentDays(start, end)
        let crossesNoon = spansDays || ( startHour < 12 && endHour >= 12 )

        let from = calendar.formatDisplayTime(from: start, needsAMPM: crossesNoon)
        let to = calendar.formatDisplayTime(from: end, needsAMPM: true)
        var more = ""
        if spansDays {
            let days = calendar.daysBetween(start, and: end)
            let ess = days == 1 ? "" : "s"
            more = " \(days) day\(ess) later"
        }

        return "\(from) - \(to)\(more)"
    }

    static func load(byId reminderId: String) -> ReminderSurface? {
        guard let reminder: Reminder = Reminder.by(id: reminderId) else {
            return nil
        }
        return load(with: reminder) as? ReminderSurface
    }

    static func load(with model: LeapModel) -> Surface? {
        guard let reminder = model as? Reminder else { return nil }

        let surface = ReminderSurface(id: reminder.id)
        let bridge = SurfaceModelBridge(id: reminder.id, surface: surface)

        bridge.reference(reminder, as: "reminder")

        bridge.bind(surface.title)
        bridge.bind(surface.startTime)
        bridge.bind(surface.endTime)
        bridge.readonlyBind(surface.refersToEvent) { (model:LeapModel) -> Bool in
            guard let reminder = model as? Reminder else { return false }
            return reminder.event != nil
        }
        bridge.readonlyBind(surface.eventTime) { (model:LeapModel) -> String? in
            guard let reminder = model as? Reminder,
                let event = reminder.event else {
                    return nil
            }
            return timeRange(event: event)
        }
        bridge.readonlyBind(surface.timeRange) { (model:LeapModel) -> String? in
            guard let reminder = model as? Reminder else { return nil }
            return timeRange(reminder: reminder)
        }
        bridge.readonlyBind(surface.reminderType) { (model:LeapModel) -> ReminderType in
            guard let reminder = model as? Reminder else { fatalError() }
            return reminder.type
        }

        surface.store = bridge
        bridge.populate(surface, with: reminder, as: "reminder")
        return surface
    }

}

extension ReminderSurface: Hashable {
    var hashValue: Int { return id.hashValue }
}


extension ReminderSurface: IGListDiffable {
    func diffIdentifier() -> NSObjectProtocol { return NSNumber(value: id.hashValue) }

    func isEqual(toDiffableObject object: IGListDiffable?) -> Bool {
        guard   let reminder = object as? ReminderSurface,
                self != reminder else {
            return false
        }

        return  (reminder.startTime.value == startTime.value) &&
                (reminder.title.value == reminder.title.value)
    }
}
