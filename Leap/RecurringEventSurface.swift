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

    var seriesRange: TimeRange?

    override func hackyShowAsReminder() {
        let realm = Realm.user()

        guard let series = Series.by(id: id) else { return }

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
        guard let series:Series = Series.by(id: seriesId) else { return nil }
        if let start = series.template.startTime(in: range),
            let concreteEvent = Event.by(id: series.generateId(for: start)) {
            return load(with: concreteEvent) as? EventSurface
        }
        return load(with: series, in: range)
    }

    static func load(with series: Series, in range: TimeRange) -> EventSurface? {
        let surface = RecurringEventSurface(id: series.id)
        surface.seriesRange = range
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
        bridge.readonlyBind(surface.recurrenceDescription) { recurringDescription(series: ($0 as! Series)) }

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


    func respondDetaching(with response: EventResponse, forceDisplay: Bool = false) -> EventSurface {
        let event = detach()!
        event.respond(with: response, forceDisplay: forceDisplay)
        return event
    }

    func detach() -> EventSurface? {
        guard let series = Series.by(id: id), let event = series.event(in: seriesRange!) else { return nil }
        let realm = Realm.user()
        try! realm.safeWrite {
            realm.add(event)
        }
        return EventSurface.load(with: event) as? EventSurface
    }

    func recurringResponseOptions(for response: EventResponse, onComplete: @escaping (ResponseScope) -> Void) -> UIAlertController {
        let alert = UIAlertController(title: "Recurring Event",
                                      message: "\"\(title.value)\" is part of a series.",
            preferredStyle: .actionSheet)

        alert.addAction(UIAlertAction(title: "\(verb(for: response)) all events in the series", style: .default) {
            action in
            self.respond(with: response, forceDisplay: true)
            onComplete(.series)
        })
        alert.addAction(UIAlertAction(title: "\(verb(for: response)) just this one", style: .default) {
            action in
            self.respondDetaching(with: response, forceDisplay: true)
            onComplete(.event)
        })
        alert.addAction(UIAlertAction(title: "Cancel", style: UIAlertActionStyle.cancel) { action in onComplete(.none) })

        return alert
    }
}

enum ResponseScope {
    case series
    case event
    case none
}
