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
    let reminderType           = SurfaceProperty<ReminderType>()
    let eventId                = SurfaceString()

    var event: EventSurface? {
        guard let id = eventId.rawValue else { return nil }
        return EventSurface.load(byId: id)
    }

    func formatEventDuration(viewedFrom day: GregorianDay? = nil) -> String? {
        return event?.formatDuration(viewedFrom: day)
    }

    var startDate: Date { return Date(timeIntervalSinceReferenceDate: TimeInterval(startTime.value)) }
    var endDate: Date? { return endTime.value == 0 ? nil : Date(timeIntervalSinceReferenceDate: TimeInterval(endTime.value)) }

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
        bridge.readonlyBind(surface.refersToEvent) { ($0 as! Reminder).event != nil }
        bridge.readonlyBind(surface.reminderType) { ($0 as! Reminder).type }
        bridge.readonlyBind(surface.eventId) { ($0 as! Reminder).event?.id }

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
                (reminder.title.value == title.value) && reminder.isShinyNew == isShinyNew
    }
}


extension ReminderSurface: Linear {
    var duration: TimeInterval {
        guard endTime.value != 0 else { return 0.0 }
        return TimeInterval(endTime.value - startTime.value)
    }
    var secondsLong: Int { return Int(duration) }
    var minutesLong: Int { return secondsLong / 60 }

    func formatDuration(viewedFrom day: GregorianDay? = nil) -> String? {
        guard let end = endDate else { return nil }
        let start = startDate

        let calendar = Calendar.current
        let startHour = calendar.component(.hour, from: start)
        let endHour = calendar.component(.hour, from: end)

        let spansDays = calendar.areOnDifferentDays(start, end)
        let crossesNoon = spansDays || ( startHour < 12 && endHour >= 12 )

        let from = calendar.formatDisplayTime(from: start, needsAMPM: crossesNoon)
        let to = calendar.formatDisplayTime(from: end, needsAMPM: true)
        var after = ""
        var before = ""
        if spansDays {
            if let day = day {
                let range = TimeRange.of(day: day)

                if start < range.start {
                    let daysEarlier = calendar.daysBetween(start, and: range.start)
                    switch daysEarlier {
                    case 0, 1:
                        before = "(Yesterday) "
                    default:
                        before = "(\(daysEarlier) days ago) "
                    }
                }

                if end > range.end {
                    let daysLater = calendar.daysBetween(range.start, and: end)
                    switch daysLater {
                    case 0, 1:
                        after = " (Tomorrow)"
                    default:
                        after = " (in \(daysLater) days)"
                    }
                } else if start < range.start {
                    after = " today"
                }

            } else {
                if spansDays {
                    let days = calendar.daysBetween(start, and: end)
                    let ess = days == 1 ? "" : "s"
                    after = " (\(days) day\(ess) later)"
                }
            }
        }

        return "\(before)\(from) - \(to)\(after)"
    }
}

