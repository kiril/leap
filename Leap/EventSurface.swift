//
//  EventSurface.swift
//  Leap
//
//  Created by Kiril Savino on 3/19/17.
//  Copyright © 2017 Single Leap, Inc. All rights reserved.
//


import Foundation
import RealmSwift

enum EventResponse {
    case none,
    yes,
    no,
    maybe
}

extension TimePerspective {
    static func compute(fromEvent event: EventSurface) -> TimePerspective {
        let now = Date()
        if event.startTime.value > now {
            return .future
        } else if event.endTime.value < now {
            return .past
        } else {
            return .current
        }
    }
}

class EventSurface: Surface, ModelLoadable {
    override var type: String { return "event" }

    var isInConflict = false
    var temporarilyForceDisplayResponseOptions = false

    // validation
    // change detection!! (because need to know when fields are dirty)
    // next: change this to NSObject, use KVO and 'public private (set) var xxx' for properties
    let title                  = SurfaceString(minLength: 1)
    let detail                 = SurfaceString()
    let startTime              = SurfaceDate()
    let endTime                = SurfaceDate()
    let timeRange              = ComputedSurfaceString<EventSurface>(by: EventSurface.eventTimeRange)
    let recurringTimeRange     = SurfaceString()
    let userIsInvited          = SurfaceBool()
    let userResponse           = SurfaceProperty<EventResponse>()
    let needsResponse          = ComputedSurfaceBool<EventSurface>(by: EventSurface.computeNeedsResponse)
    let isConfirmed            = ComputedSurfaceBool<EventSurface>(by: EventSurface.computeIsConfirmed)
    let perspective            = ComputedSurfaceProperty<TimePerspective,EventSurface>(by: TimePerspective.compute)
    let percentElapsed         = ComputedSurfaceFloat<EventSurface>(by: EventSurface.computeElapsed)
    let invitationSummary      = SurfaceString()
    let locationSummary        = SurfaceString()
    let isRecurring            = SurfaceBool()
    let origin                 = SurfaceProperty<Origin>()
    let hasAlarms              = SurfaceBool()
    let alarmSummary           = SurfaceString()
    let participants           = SurfaceProperty<[ParticipantSurface]>()


    func intersectsWith(_ other: EventSurface) -> Bool {
        if endTime.value <= other.startTime.value || other.endTime.value <= startTime.value {
            return false
        }
        return true
    }

    static func computeNeedsResponse(event: EventSurface) -> Bool {
        return event.userResponse.value == .none
    }

    static func computeIsConfirmed(event: EventSurface) -> Bool {
        if event.userResponse.value == .yes {
            return true
        } else {
            return false
        }
    }

    static func eventTimeRange(event: EventSurface) -> String {
        let start = event.startTime.value
        let end = event.endTime.value

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

    static func computeElapsed(event: EventSurface) -> Float {
        let now = Date()

        if Calendar.current.isDate(now, after: event.endTime.value) {
            return 1.0
        } else if Calendar.current.isDate(now, before: event.startTime.value) {
            return 0.0
        } else {
            return Float(now.seconds(since: event.startTime.value))/Float(event.endTime.value.seconds(since: event.startTime.value))
        }
    }

    func hackyCreateReminderFromEvent() {
        // Okay, this is going to be mostly to get it displaying on the screen, consider this prototype code.

        let realm = Realm.user()

        let event = Event.by(id: id)!

        let data : [String: Any] = [
            "title": event.title,
            "event": event,
            "startTime": event.startTime,
            "endTime": event.endTime,
            "typeString": ReminderType.event.rawValue,
        ]

        let reminder: Reminder = Reminder(value: data)
        try! realm.write {
            reminder.insert(into: realm)
            event.status = .archived
        }
    }

    static func load(fromModel event: LeapModel) -> Surface? {
        return load(byId: event.id)
    }

    static func load(byId eventId: String) -> EventSurface? {
        guard let event:Event = Event.by(id: eventId) else {
            return nil
        }

        let surface = EventSurface(id: eventId)
        let bridge = SurfaceModelBridge(id: eventId, surface: surface)

        bridge.reference(event, as: "event")

        bridge.bind(surface.title)
        bridge.bind(surface.detail)
        bridge.readonlyBind(surface.hasAlarms) { (m:LeapModel) -> Bool in
            return (m as! Event).alarms.count > 0
        }
        bridge.readonlyBind(surface.alarmSummary) { (m:LeapModel) -> String? in
            guard let event = m as? Event, event.alarms.count > 0 else { return nil }
            var summary = "Alarm "
            let initialLength = summary.characters.count
            for alarm in event.alarms {
                if summary.characters.count > initialLength {
                    summary += ", "
                }

                switch alarm.type {
                case .absolute:
                    let formatter = DateFormatter()
                    formatter.locale = Locale.current
                    formatter.setLocalizedDateFormatFromTemplate("MMMdy")
                    let dateString = formatter.string(from: alarm.absoluteTime!)
                    summary += dateString

                case .location:
                    summary += "on a certain location"

                case .relative:
                    let seconds = alarm.relativeOffset
                    if seconds > 0 {
                        summary += "\(seconds.durationString) after"
                    } else if seconds == 0 {
                        summary += "at time of event"
                    } else {
                        summary += "\(abs(seconds).durationString) before"
                    }
                }
            }
            return summary
        }
        bridge.readonlyBind(surface.origin) { (m) -> Any? in
            if let e = m as? Event {
                return e.origin
            }
            return Origin.unknown
        }
        bridge.readonlyBind(surface.isRecurring, populateWith: { (m:LeapModel) in
            if let e = m as? Event {
                return e.isRecurring
            }
            return false
        })

        func getStartTime(model:LeapModel) -> Any? {
            guard let event = model as? Event else {
                fatalError("OMG wrong type or something \(model)")
            }
            return event.startDate
        }
        func setStartTime(model:LeapModel, value: Any?) {
            guard let event = model as? Event, let date = value as? Date else {
                fatalError("OMG wrong type or something \(model)")
            }

            event.startTime = date.secondsSinceReferenceDate
        }
        bridge.bind(surface.startTime, populateWith: getStartTime, on: "event", persistWith: setStartTime)

        func getEndTime(model:LeapModel) -> Any? {
            guard let event = model as? Event else {
                fatalError("OMG wrong type or something \(model)")
            }
            return event.endDate
        }
        func setEndTime(model:LeapModel, value: Any?) {
            guard let event = model as? Event, let date = value as? Date else {
                fatalError("OMG wrong type or something \(model)")
            }

            event.endTime = date.secondsSinceReferenceDate
        }
        bridge.bind(surface.endTime, populateWith: getEndTime, on: "event", persistWith: setEndTime)

        bridge.readonlyBind(surface.userIsInvited) { (model:LeapModel) in
            guard let thing = model as? Temporality, let me = thing.me else {
                return false
            }
            return me.ownership == .invitee
        }

        bridge.readonlyBind(surface.locationSummary) { (model:LeapModel) -> String? in
            guard let event = model as? Event, let location = event.locationString, location.characters.count > 0 else {
                return nil
            }
            return location
        }

        bridge.readonlyBind(surface.invitationSummary) { (model:LeapModel) -> String? in
            let someone = "Someone"
            let someCalendar = "Shared Calendar"
            if let event = model as? Event {
                switch event.origin {
                case .share:
                    if  let calendar = event.linkedCalendars.first,
                        let organizer = event.organizer,
                        let from = organizer.nameOrEmail {
                        return "\(from) -> \(calendar.title)"
                    } else if   let organizer = event.organizer,
                                let from = organizer.nameOrEmail {
                        return "from \(from)"
                    } else if let calendar = event.linkedCalendars.first {
                        return "via \(calendar.title)"
                    }
                    return "via Shared Calendar"

                case .invite:
                    let from = event.organizer?.nameOrEmail
                    var to = ""

                    for participant in event.invitees {
                        if participant == event.organizer {
                            continue
                        }
                        let name = participant.isMe ? "Me" : participant.nameOrEmail ?? someone
                        if !to.characters.isEmpty {
                            to += ", "
                        }
                        to += name
                    }

                    guard let fromName = from else {
                        return "→ \(to)"
                    }

                    if event.me != nil && to == "Me" {
                        if event.me!.engagement == .engaged {
                            return "with \(fromName)"
                        } else {
                            return "from \(fromName)"
                        }
                    }

                    guard !to.characters.isEmpty else {
                        return "from \(fromName)"
                    }

                    return "\(fromName) → \(to)"

                case .subscription:
                    return "via \(event.linkedCalendars.first?.title ?? someCalendar)"

                case .personal:
                    return nil

                case .unknown:
                    return nil
                }
            } else {
                return "Not an Event"
            }
        }

        func getEventResponse(model:LeapModel) -> Any? {
            guard   let thing = model as? Temporality,
                    let me = thing.me else {
                return EventResponse.none
            }

            switch me.engagement {
            case .undecided, .none:
                return EventResponse.none
            case .engaged:
                return EventResponse.yes
            case .disengaged:
                return EventResponse.no
            case .tracking:
                return EventResponse.maybe
            }
        }
        func setEventResponse(model:LeapModel, value: Any?) {
            guard   let thing = model as? Temporality,
                    let response = value as? EventResponse else {
                fatalError("OMG wrong type or something \(model)")
                // could this happen just because you are no longer invited?
            }

            if thing.me == nil {
                // We need to add a participant if you don't have 

                let personData: [String:Any?] = ["isMe": true]
                let enforcedMe = Person(value: personData)

                let participantData: [String: Any?] = ["person": enforcedMe]
                let enforcedMeParticipation = Participant(value: participantData)

                thing.participants.append(enforcedMeParticipation)
            }

            guard let me = thing.me else {
                fatalError("me should be enforced")
            }

            // now handle other engagement settings
            switch response {
            case .none:
                me.engagement = .undecided
            case .yes:
                me.engagement = .engaged
            case .no:
                me.engagement = .disengaged
            case .maybe:
                me.engagement = .tracking
            }
        }
        bridge.bind(surface.userResponse,
                    populateWith: getEventResponse,
                    on: "event",
                    persistWith: setEventResponse)

        bridge.readonlyBind(surface.recurringTimeRange) { (model:LeapModel) -> String? in
            guard let event = model as? Event else { return nil }
            guard let seriesId = event.seriesId, let series = Series.by(id: seriesId) else { return nil }

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
            let startHour = calendar.component(.hour, from: event.startDate)
            let endHour = calendar.component(.hour, from: event.endDate)

            let spansDays = calendar.areOnDifferentDays(event.startDate, event.endDate)
            let crossesNoon = spansDays || ( startHour < 12 && endHour >= 12 )

            let from = calendar.formatDisplayTime(from: event.startDate, needsAMPM: crossesNoon)
            let to = calendar.formatDisplayTime(from: event.endDate, needsAMPM: true)
            var more = ""
            if spansDays {
                let days = calendar.daysBetween(event.startDate, and: event.endDate)
                let ess = days == 1 ? "" : "s"
                more = " \(days) day\(ess) later"
            }
            
            return "\(recurrence) from \(from) - \(to)\(more)"
        }

        bridge.readonlyBind(surface.participants) { (m:LeapModel) -> [ParticipantSurface] in
            var participants: [ParticipantSurface] = []

            guard let event = m as? Event else { return participants }

            for participant in event.participants {
                if let participantSurface = ParticipantSurface.load(fromModel: participant) as? ParticipantSurface {
                    participants.append(participantSurface)
                }
            }

            return participants
        }

        surface.store = bridge
        bridge.populate(surface)
        return surface
    }

    func buttonText(forResponse response: EventResponse) -> String? {
        switch origin.value {
        case .invite:
            switch response {
            case .yes:
                return "Yes"
            case .no:
                return "No"
            case .maybe:
                return "Maybe"
            case .none:
                return nil
            }
        case .share, .subscription:
            switch response {
            case .yes:
                return "Join"
            case .no:
                return "No"
            case .maybe:
                return "Maybe"
            case .none:
                return nil
            }
        case .personal, .unknown:
            switch response {
            case .yes:
                return "Confirm"
            case .no:
                return "No"
            case .maybe:
                return "Maybe"
            case .none:
                return nil
            }
        }
    }
}

extension EventSurface: Hashable {
    var hashValue: Int { return id.hashValue }
}

extension EventSurface {
    var range: TimeRange? {
        return TimeRange(start: startTime.value,
                         end: endTime.value)
    }
}
