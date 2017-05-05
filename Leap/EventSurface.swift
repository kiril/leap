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


    static func from(_ engagement: Engagement) -> EventResponse {
        switch engagement {
        case .undecided, .none:
            return .none
        case .engaged:
            return .yes
        case .disengaged:
            return .no
        case .tracking:
            return .maybe
        }
    }

    func asEngagement() -> Engagement {
        switch self {
        case .none:
            return .undecided
        case .yes:
            return .engaged
        case .no:
            return .disengaged
        case .maybe:
            return .tracking
        }
    }
}

enum Handedness {
    case left
    case right
}

enum Overlap {
    case identical
    case staggered
    case justified(direction:Handedness)
    case none
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
    let timeString             = ComputedSurfaceString<EventSurface>(by: { $0.formatDuration()! })
    let recurrenceDescription  = SurfaceString()
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
    let arrivalTime            = SurfaceDate()
    let departureTime          = SurfaceDate()
    let arrivalReferenceEvent  = SurfaceProperty<EventSurface>()
    let departureReferenceEvent = SurfaceProperty<EventSurface>()
    let agenda                 = SurfaceProperty<Checklist?>()

    var isEligibleForConflict: Bool { return isConfirmed.value || userResponse.value == .none }
    var canBeConflictedWith: Bool { return isConfirmed.value }

    var hasCustomArrival: Bool { return arrivalTime.value != startTime.value }
    var hasCustomDeparture: Bool { return departureTime.value != endTime.value }

    var hasAgenda: Bool { return agenda.rawValue != nil }

    func responseNeedsClarification(for response: EventResponse) -> Bool {
        return false
    }

    func conflict(with other: EventSurface, assumingCommitted: Bool = false) -> Overlap {
        guard other != self && (isEligibleForConflict || assumingCommitted) && other.canBeConflictedWith else { return .none }
        return intersection(with: other)
    }

    func conflicts(with other: EventSurface, assumingCommitted: Bool = false) -> Bool {
        switch conflict(with: other, assumingCommitted: assumingCommitted) {
        case .none:
            return false
        default:
            return true
        }
    }

    func conflicts(in others: [EventSurface], assumingCommitted: Bool = false) -> [(Overlap,EventSurface)] {
        var ret: [(Overlap,EventSurface)] = []

        for event in others {
            let overlap = conflict(with: event, assumingCommitted: assumingCommitted)

            switch overlap {
            case .none:
                continue

            default:
                ret.append((overlap, event))
            }
        }

        return ret
    }

    func firstConflict(in others: [EventSurface], assumingCommitted: Bool = false) -> (Overlap,EventSurface)? {
        for event in others {
            let overlap = conflict(with: event, assumingCommitted: assumingCommitted)

            switch overlap {
            case .none:
                continue

            default:
                return (overlap, event)
            }
        }

        return nil
    }

    func intersection(with other: EventSurface) -> Overlap {
        if endTime.value <= other.startTime.value || other.endTime.value <= startTime.value {
            return .none
        }

        if endTime.value == other.endTime.value && startTime.value == other.startTime.value {
            return .identical
        }

        if endTime.value == other.endTime.value {
            return .justified(direction: .right)
        }

        if startTime.value == other.startTime.value {
            return .justified(direction: .left)
        }

        return .staggered
    }

    func leaveEarly(for other: EventSurface) -> EventSurface {
        let otherStart = other.startTime.value
        guard otherStart > startTime.value && otherStart < endTime.value else { fatalError() }
        return depart(at: otherStart)
    }

    func joinLate(for other: EventSurface) -> EventSurface {
        let otherEnd = other.endTime.value
        guard otherEnd > startTime.value && otherEnd < endTime.value else { fatalError() }
        return arrive(at: otherEnd)
    }

    func depart(at departureTime: Date) -> EventSurface {
        var me = self
        if let recurring = self as? RecurringEventSurface {
            me = recurring.detach()!
        }

        me.departureTime.update(to: departureTime)
        try! me.flush()
        return me
    }

    func arrive(at arrivalTime: Date) -> EventSurface {
        var me = self
        if let recurring = self as? RecurringEventSurface {
            me = recurring.detach()!
        }

        me.arrivalTime.update(to: arrivalTime)
        try! me.flush()
        return me
    }

    func splitTime(with other: EventSurface, for overlap: Overlap) -> (EventSurface, EventSurface) {
        assert(!(self is RecurringEventSurface) || !(other is RecurringEventSurface))

        var me: EventSurface = self
        var them: EventSurface = other

        switch overlap {
        case .identical:
            let diff = endTime.value.timeIntervalSince(startTime.value)
            let midpoint = Date(timeIntervalSinceReferenceDate: startTime.value.timeIntervalSinceReferenceDate + diff/2)

            me = self.depart(at: midpoint)
            them = other.arrive(at: midpoint)

        case .staggered:
            let first = startTime.value < other.startTime.value ? self : other
            let second = first == self ? other : self
            let startOfSecond = second.startTime.value
            let endOfFirst = first.endTime.value

            guard endOfFirst < startOfSecond else { return (me, them) }

            let diff = startOfSecond.timeIntervalSince(endOfFirst)
            let midpoint = Date(timeIntervalSinceReferenceDate: endOfFirst.timeIntervalSinceReferenceDate + diff/2)

            let a = first.depart(at: midpoint)
            let b = second.arrive(at: midpoint)

            me = (first == me ? a : b)
            them = (first == me ? b : a)

        case let .justified(direction):
            switch direction {
            case .left:
                let shorter = endTime.value < other.endTime.value ? self : other
                let longer = shorter == self ? other : self
                let amount = shorter.endTime.value.timeIntervalSince(shorter.startTime.value) / 2
                let midpoint = Date(timeIntervalSinceReferenceDate: shorter.startTime.value.timeIntervalSinceReferenceDate + amount)

                let a = shorter.depart(at: midpoint)
                let b = longer.arrive(at: midpoint)

                me = (shorter == me ? a : b)
                them = (shorter == me ? b : a)

            case .right:
                let shorter = endTime.value < other.endTime.value ? self : other
                let longer = shorter == self ? other : self
                let amount = shorter.endTime.value.timeIntervalSince(shorter.startTime.value) / 2
                let midpoint = Date(timeIntervalSinceReferenceDate: shorter.startTime.value.timeIntervalSinceReferenceDate + amount)
                let a = shorter.arrive(at: midpoint)
                let b = longer.depart(at: midpoint)

                me = (shorter == me ? a : b)
                them = (shorter == me ? b : a)
            }

        case .none:
            return (me, them)
        }

        return (me, them)
    }

    func verb(for response: EventResponse) -> String {
        switch origin.value {
        case .invite:
            switch response {
            case .yes:
                return "Accept"
            case .no:
                return "Decline"
            case .maybe:
                return "Maybe"
            case .none:
                fatalError()
            }
        case .share, .subscription:
            switch response {
            case .yes:
                return "Join"
            case .no:
                return "Archive"
            case .maybe:
                return "Maybe"
            case .none:
                fatalError()
            }
        case .personal, .unknown:
            switch response {
            case .yes:
                return "Confirm"
            case .no:
                return "Archive"
            case .maybe:
                return "Maybe"
            case .none:
                fatalError()
            }
        }
    }

    func respond(with response: EventResponse, forceDisplay: Bool = false) {
        userResponse.update(to: response)
        temporarilyForceDisplayResponseOptions = forceDisplay
        try! flush()
    }

    static func computeNeedsResponse(event: EventSurface) -> Bool {
        return event.userResponse.value == .none
    }

    static func computeIsConfirmed(event: EventSurface) -> Bool {
        return event.userResponse.value == .yes
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

    func hackyShowAsReminder() {
        // Okay, this is going to be mostly to get it displaying on the screen, consider this prototype code.

        let realm = Realm.user()

        guard let event = Event.by(id: id) else { return }

        let data: ModelInitData = ["title": event.title,
                                   "event": event,
                                   "startTime": event.startTime,
                                   "endTime": event.endTime,
                                   "typeString": ReminderType.event.rawValue,]

        let reminder: Reminder = Reminder(value: data)
        try! realm.write {
            reminder.insert(into: realm)
            event.status = .archived
        }
    }

    static func invitationSummary(of event: Event) -> String? {
        return invitationSummary(origin: event.origin,
                                 calendar: event.linkedCalendars.first,
                                 me: event.me,
                                 organizer: event.organizer,
                                 invitees: event.invitees)
    }

    static func invitationSummary(origin: Origin,
                                  calendar: LegacyCalendar?,
                                  me: Participant?,
                                  organizer: Participant?,
                                  invitees: [Participant]) -> String? {
        let someone = "Someone"
        let someCalendar = "Shared Calendar"

        switch origin {
        case .share:
            if  let calendar = calendar,
                let organizer = organizer,
                let from = organizer.nameOrEmail {
                return "\(from) -> \(calendar.title)"
            } else if   let organizer = organizer,
                let from = organizer.nameOrEmail {
                return "from \(from)"
            } else if let calendar = calendar {
                return "via \(calendar.title)"
            }
            return "via Shared Calendar"

        case .invite:
            let from = organizer?.nameOrEmail
            var to = ""

            for participant in invitees {
                if participant == organizer {
                    continue
                }
                let name = participant.isMe ? "Me" : participant.nameOrEmail ?? someone
                if !to.isEmpty {
                    to += ", "
                }
                to += name
            }

            guard let fromName = from else {
                return "→ \(to)"
            }

            if let me = me, to == "Me" {
                if me.engagement == .engaged {
                    return "with \(fromName)"
                } else {
                    return "from \(fromName)"
                }
            }

            guard !to.isEmpty else {
                return "from \(fromName)"
            }

            return "\(fromName) → \(to)"
            
        case .subscription:
            return "via \(calendar?.title ?? someCalendar)"
            
        case .personal:
            return nil
            
        case .unknown:
            return nil
        }

    }

    static func load(byId eventId: String) -> EventSurface? {
        guard let event:Event = Event.by(id: eventId) else {
            return nil
        }
        return load(with: event) as? EventSurface
    }

    static func load(with model: LeapModel) -> Surface? {
        guard let event = model as? Event else { return nil }
        let surface = EventSurface(id: event.id)
        let bridge = SurfaceModelBridge(id: event.id, surface: surface)

        bridge.reference(event, as: "event")

        bridge.bind(surface.title)
        bridge.bind(surface.detail)
        bridge.bind(surface.agenda)

        bridge.readonlyBind(surface.hasAlarms) { !($0 as! Event).alarms.isEmpty }
        bridge.readonlyBind(surface.alarmSummary) { ($0 as! Event).alarms.summarize() }
        bridge.readonlyBind(surface.origin) { ($0 as! Event).origin }
        bridge.readonlyBind(surface.isRecurring) { ($0 as! Event).isRecurring }

        let getStartTime = { (m:LeapModel) in return (m as! Event).startDate }
        let setStartTime = { (m:LeapModel, v: Any?) in (m as! Event).startTime = (v as! Date).secondsSinceReferenceDate }
        bridge.bind(surface.startTime, populateWith: getStartTime, on: "event", persistWith: setStartTime)

        let getEndTime = {(m:LeapModel) in return (m as! Event).endDate}
        let setEndTime = {(m:LeapModel, v:Any?) in (m as! Event).endTime = (v as! Date).secondsSinceReferenceDate }
        bridge.bind(surface.endTime, populateWith: getEndTime, on: "event", persistWith: setEndTime)

        func getArrivalTime(model: LeapModel) -> Any? {
            let event = model as! Event
            guard event.arrivalOffset != 0 else {
                return event.startDate
            }
            return Date(timeIntervalSinceReferenceDate: TimeInterval(event.startTime + event.arrivalOffset))
        }
        func setArrivalTime(model: LeapModel, value: Any?) {
            let event = model as! Event
            guard let arrivalTime = value as? Date else { return }
            event.arrivalOffset = arrivalTime.secondsSinceReferenceDate - event.startTime
        }
        bridge.bind(surface.arrivalTime, populateWith: getArrivalTime, on: "event", persistWith: setArrivalTime)


        func getDepartureTime(model: LeapModel) -> Any? {
            let event = model as! Event
            guard event.departureOffset != 0 else {
                return event.endDate
            }
            return Date(timeIntervalSinceReferenceDate: TimeInterval(event.endTime + event.departureOffset))
        }
        func setDepartureTime(model: LeapModel, value: Any?) {
            let event = model as! Event
            guard let departureTime = value as? Date else { return }
            event.departureOffset = departureTime.secondsSinceReferenceDate - event.endTime
        }
        bridge.bind(surface.departureTime, populateWith: getDepartureTime, on: "event", persistWith: setDepartureTime)

        bridge.readonlyBind(surface.userIsInvited) { ($0 as! Event).origin == .invite }

        bridge.readonlyBind(surface.locationSummary) { (model:LeapModel) -> String? in
            guard let location = (model as! Event).locationString, !location.isEmpty else {
                return nil
            }
            return location
        }

        bridge.readonlyBind(surface.invitationSummary) { invitationSummary(of: ($0 as! Event)) }

        bridge.bind(surface.userResponse,
                    populateWith: { EventResponse.from(($0 as! Event).engagement) },
                    on: "event",
                    persistWith: { ($0 as! Event).engagement = ($1 as! EventResponse).asEngagement() })

        bridge.readonlyBind(surface.recurrenceDescription) { (model:LeapModel) -> String? in
            guard let event = model as? Event else { return nil }
            guard let seriesId = event.seriesId, let series = Series.by(id: seriesId) else { return nil }
            return recurringDescription(series: series)
        }

        bridge.readonlyBind(surface.participants) { (m:LeapModel) -> [ParticipantSurface] in
            var participants: [ParticipantSurface] = []

            guard let event = m as? Event else { return participants }

            for participant in event.participants {
                if let participantSurface = ParticipantSurface.load(with: participant) as? ParticipantSurface {
                    participants.append(participantSurface)
                }
            }

            return participants
        }

        surface.store = bridge
        bridge.populate(surface, with: event, as: "event")
        return surface
    }

    static func recurringDescription(series: Series) -> String? {
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
        let now = Date()
        let range = TimeRange(start: now, end: calendar.date(byAdding: .day, value: 1, to: now)!)!
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
            more = " \(days) day\(ess) later"
        }

        return "\(recurrence) from \(from) - \(to)\(more)"
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
                return "Archive"
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
                return "Archive"
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

extension Array where Element: EventSurface {
    func openTimes(in timeRange: TimeRange) -> [TimeRange] {
        var openTimeRanges = [timeRange]
        for event in self {
            guard let range = event.range else { continue }
            openTimeRanges = openTimeRanges.timeRangesByExcluding(timeRange: range)
            if openTimeRanges.isEmpty { break }
        }
        return openTimeRanges
    }
}


extension EventSurface: Comparable {
    static func < (lhs: EventSurface, rhs: EventSurface) -> Bool {
        return lhs.startTime.value < lhs.startTime.value
    }
}


extension List where Element: Alarm {
    func summarize() -> String {
        var summary = "Alarm "
        for (i, alarm) in self.enumerated() {
            if i > 0 {
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
}



extension EventSurface: Linear {
    var duration: TimeInterval {
        return endTime.value.timeIntervalSinceReferenceDate - startTime.value.timeIntervalSinceReferenceDate
    }
    var secondsLong: Int { return Int(duration) }
    var minutesLong: Int { return secondsLong / 60 }

    func formatDuration() -> String? {
        let start = startTime.value
        let end = endTime.value

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
}
