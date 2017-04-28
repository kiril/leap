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
    let refersToEvent          = SurfaceBool()
    let eventTime              = SurfaceString()

    static func load(fromModel reminder: LeapModel) -> Surface? {
        return load(byId: reminder.id)
    }


    static func eventTimeRange(event: Event) -> String {
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

    static func load(byId reminderId: String) -> ReminderSurface? {
        guard let reminder: Reminder = Reminder.by(id: reminderId) else {
            return nil
        }

        let surface = ReminderSurface(id: reminderId)
        let bridge = SurfaceModelBridge(id: reminderId, surface: surface)

        bridge.reference(reminder, as: "reminder")

        bridge.bind(surface.title)
        bridge.bind(surface.startTime)
        bridge.readonlyBind(surface.refersToEvent) { (model:LeapModel) -> Bool in
            guard let reminder = model as? Reminder else { return false }
            return reminder.event != nil
        }
        bridge.readonlyBind(surface.eventTime) { (model:LeapModel) -> String? in
            guard let reminder = model as? Reminder,
                let event = reminder.event else {
                    return nil
            }
            return eventTimeRange(event: event)
        }

        surface.store = bridge
        bridge.populate(surface)
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
