//
//  RecurringEventSurface.swift
//  Leap
//
//  Created by Kiril Savino on 5/3/17.
//  Copyright © 2017 Single Leap, Inc. All rights reserved.
//

import Foundation
import RealmSwift

class RecurringEventSurface: EventSurface {

    var seriesId: String!
    var seriesRange: TimeRange!

    override func hackyShowAsReminder() {
        let realm = Realm.user()

        guard let series = getSeries() else { return }

        let reminderSeries = series.clone()
        reminderSeries.referencing = series
        reminderSeries.type = .reminder
        reminderSeries.template.reminderTypeString = ReminderType.event.rawValue

        try! realm.write {
            reminderSeries.insert(into: realm)
            series.status = .archived
        }
    }

    static func load(seriesId: String, in range: TimeRange) -> EventSurface? {
        guard let series = Series.by(id: seriesId) else { return nil }
        if let start = series.template.startTime(in: range),
            let concreteEvent = Event.by(id: series.generateId(for: start)) {
            return load(with: concreteEvent) as? EventSurface
        }
        return load(with: series, in: range)
    }

    override class func load(byId eventId: String) -> EventSurface? {
        fatalError("this doesn't work yet for RecurringEventSurface. We have plans to do it, though. Until we do, pass around the Surface itself")
    }

    static func invitationSummary(series: Series) -> String? {
        return invitationSummary(origin: series.template.origin,
                                 calendar: series.template.linkedCalendars.first,
                                 me: series.template.participants.me,
                                 organizer: series.template.organizer,
                                 invitees: series.template.invitees)
    }


    override func responseNeedsClarification(for response: EventResponse) -> Bool {
        if self.needsResponse.value && response == .yes {
            return false
        } else {
            return true
        }
    }

    func detach() -> EventSurface? {
        guard let series = getSeries(), let event = series.event(in: seriesRange) else { return nil }
        let realm = Realm.user()
        try! realm.safeWrite {
            realm.add(event)
        }
        self.isShinyNew = false
        return EventSurface.load(with: event) as? EventSurface
    }

    func getSeries() -> Series? {
        return Series.by(id: self.seriesId)
    }

    func recurringUpdateOptions(for verb: String, onComplete: @escaping (ResponseScope) -> Void) -> UIAlertController {
        let alert = UIAlertController(title: "Recurring Event",
                                      message: "\"\(title.value)\" is part of a series.",
            preferredStyle: .actionSheet)

        alert.addAction(UIAlertAction(title: "\(verb) all events in the series", style: .default) {
            action in
            onComplete(.series)
        })
        alert.addAction(UIAlertAction(title: "\(verb) just this one", style: .default) {
            action in
            onComplete(.event)
        })
        alert.addAction(UIAlertAction(title: "Cancel", style: UIAlertActionStyle.cancel) { action in onComplete(.none) })

        return alert
    }

    func isSplitCompatible(with other: RecurringEventSurface) -> Bool {
        guard let s1 = self.getSeries(), let s2 = other.getSeries() else { return false }
        return s1.coRecurs(with: s2, after: seriesRange.start)
    }

    static func recurringDescription(series: Series, in range: TimeRange) -> String? {
        var recurrence = "Repeating"

        switch series.recurrence.frequency {
        case .daily:
            recurrence = "Daily"

        case .weekly:
            recurrence = "Weekly"
            if series.recurrence.daysOfWeek.count > 0 {
                let weekdays = series.recurrence.daysOfWeek.map({ $0.raw }).sorted()
                if weekdays == GregorianWeekdays {
                    recurrence = "Weekdays"
                } else if weekdays == GregorianWeekends {
                    recurrence = "Weekends"
                } else {
                    recurrence = ""

                    for (i, weekday) in weekdays.enumerated() {
                        if i > 0 {
                            if i == weekdays.count-1 {
                                recurrence += " and "
                            } else {
                                recurrence += ", "
                            }
                        }
                        recurrence += "\(weekday.weekdayString)s"
                    }
                }
            }

        case .monthly:
            recurrence = "Monthly"

        case .yearly:
            recurrence = "Yearly"

        case .unknown:
            return nil
        }


        let calendar = Calendar.current
        let startDate = series.template.startTime(in: range)!
        let endDate = series.template.endTime(in: range)!

        let startHour = calendar.component(.hour, from: startDate)
        let endHour = calendar.component(.hour, from: endDate)

        let spansDays = calendar.areOnDifferentDays(startDate, endDate)
        let crossesNoon = spansDays || ( startHour < 12 && endHour >= 12 )

        let from = calendar.formatDisplayTime(from: startDate, needsAMPM: crossesNoon)
        let to = calendar.formatDisplayTime(from: endDate, needsAMPM: true)
        var more = ""
        if spansDays {
            let days = calendar.daysBetween(startDate, and: endDate)
            let ess = days == 1 ? "" : "s"
            more = " (\(days) day\(ess) later)"
        }
        
        return "\(recurrence) from \(from) - \(to)\(more)"
    }

    static func load(with series: Series, in range: TimeRange) -> EventSurface? {
        let surface = RecurringEventSurface(id: series.generateId(for: series.template.startTime(in: range)!))
        surface.seriesRange = range
        surface.seriesId = series.id
        let bridge = SurfaceModelBridge(id: series.id, surface: surface)

        bridge.reference(series, as: "series")
        bridge.readonlyBind(surface.title)
        bridge.readonlyBind(surface.detail) { ($0 as! Series).template.detail }
        bridge.readonlyBind(surface.agenda) { ($0 as! Series).template.agenda }
        bridge.readonlyBind(surface.hasAlarms) { !($0 as! Series).template.alarms.isEmpty }
        bridge.readonlyBind(surface.alarmSummary) { ($0 as! Series).template.alarms.summarize() }
        bridge.readonlyBind(surface.origin) { ($0 as! Series).template.origin }
        bridge.readonlyBind(surface.isRecurring) { (m:LeapModel) in return true }


        bridge.readonlyBind(surface.startTime) { ($0 as! Series).template.startTime(in: range) }
        bridge.readonlyBind(surface.endTime) { ($0 as! Series).template.endTime(in: range) }
        bridge.readonlyBind(surface.arrivalTime) { ($0 as! Series).template.startTime(in: range) }
        bridge.readonlyBind(surface.departureTime) { ($0 as! Series).template.endTime(in: range) }
        bridge.readonlyBind(surface.userIsInvited) { (model:LeapModel) in
            guard let series = model as? Series, let me = series.template.participants.me else {
                return false
            }
            return me.ownership == .invitee
        }

        bridge.readonlyBind(surface.locationSummary) { (model:LeapModel) -> String? in
            guard let series = model as? Series, let location = series.template.locationString, !location.isEmpty else {
                return nil
            }
            return location
        }

        bridge.readonlyBind(surface.invitationSummary) { invitationSummary(series: ($0 as! Series)) }
        bridge.bind(surface.userResponse,
                    populateWith: { (m:LeapModel) in EventResponse.from((m as! Series).engagement) },
                    on: "series",
                    persistWith: { ($0 as! Series).engagement = ($1 as! EventResponse).asEngagement() })
        bridge.readonlyBind(surface.recurrenceDescription) { recurringDescription(series: ($0 as! Series), in: surface.seriesRange) }

        bridge.readonlyBind(surface.participants) { (m:LeapModel) -> [ParticipantSurface] in
            let series = m as! Series
            var participants: [ParticipantSurface] = []

            for participant in series.template.participants {
                if let participantSurface = ParticipantSurface.load(with: participant) as? ParticipantSurface {
                    participants.append(participantSurface)
                }
            }

            return participants
        }

        surface.store = bridge
        bridge.populate(surface, with: series, as: "series")
        
        return surface
    }
}

enum ResponseScope {
    case series
    case event
    case none
}
