//
//  EventSurface.swift
//  Leap
//
//  Created by Kiril Savino on 3/19/17.
//  Copyright © 2017 Single Leap, Inc. All rights reserved.
//


import Foundation
import RealmSwift

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
    let perspective            = ComputedSurfaceProperty<TimePerspective,EventSurface>(by: EventSurface.computePerspective)
    let userAttendancePerspective = ComputedSurfaceProperty<TimePerspective,EventSurface>(by: EventSurface.computeUserAttendancePerspective)
    let percentElapsed         = ComputedSurfaceFloat<EventSurface>(by: EventSurface.computeElapsed)
    let percentUserAttendanceElapsed = ComputedSurfaceFloat<EventSurface>(by: EventSurface.computeUserAttendanceElapsed)
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

    var isDetached: Bool {
        if self is RecurringEventSurface {
            return false
        }
        return self.isRecurring.value
    }

    var hasDetail: Bool { return detail.rawValue != nil && detail.value.hasNonWhitespaceCharacters }

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
        if departureTime.value <= other.arrivalTime.value || other.departureTime.value <= arrivalTime.value {
            return .none
        }

        if departureTime.value == other.departureTime.value && arrivalTime.value == other.arrivalTime.value {
            return .identical
        }

        if departureTime.value == other.departureTime.value {
            return .justified(direction: .right)
        }

        if arrivalTime.value == other.arrivalTime.value {
            return .justified(direction: .left)
        }

        return .staggered
    }



    func resolveConflict(with other: EventSurface, in overlap: Overlap, by resolution: TimeConflictResolution, detaching: Bool) -> (EventSurface, EventSurface) {
        var left = detaching ? (self as? RecurringEventSurface)?.detach() ?? self : self
        var right = detaching ? (other as? RecurringEventSurface)?.detach() ?? other : other

        switch resolution {
        case .leaveEarly:
            // whichever starts first, we leave in time for the second
            if left.arrivesEarlier(than: right) {
                left = left.leaveEarly(for: right, detaching: detaching)
            } else {
                right = right.leaveEarly(for: left, detaching: detaching)
            }

        case .arriveLate:
            // whichever ends later, we arrive at when the first one is done
            if left.departsLater(than: right) {
                left = left.joinLate(for: right, detaching: detaching)
            } else {
                right = right.joinLate(for: left, detaching: detaching)
            }

        case .splitEvenly:
            (left, right) = left.splitTime(with: right, for: overlap, detaching: detaching)

        case let .decline(side):
            switch side {
            case .left:
                left.respond(with: .no, forceDisplay: true, detaching: detaching)

            case .right:
                right.respond(with: .no, forceDisplay: true, detaching: detaching)
            }

        case .none:
            break // cancel tapped
        }

        return (left, right)
    }

    func leaveEarly(for other: EventSurface, detaching: Bool) -> EventSurface {
        let otherStart = other.startTime.value
        guard otherStart > startTime.value && otherStart < endTime.value else { fatalError() }
        return depart(at: otherStart, detaching: detaching)
    }

    func joinLate(for other: EventSurface, detaching: Bool) -> EventSurface {
        let otherEnd = other.endTime.value
        guard otherEnd > startTime.value && otherEnd < endTime.value else { fatalError() }
        return arrive(at: otherEnd, detaching: detaching)
    }

    func depart(at departureTime: Date, detaching: Bool) -> EventSurface {
        var me = self
        if let recurring = self as? RecurringEventSurface, detaching {
            me = recurring.detach()!
        }

        me.departureTime.update(to: departureTime)
        try! me.flush()
        return me
    }

    func arrive(at arrivalTime: Date, detaching: Bool) -> EventSurface {
        var me = self
        if let recurring = self as? RecurringEventSurface, detaching {
            me = recurring.detach()!
        }

        me.arrivalTime.update(to: arrivalTime)
        try! me.flush()
        return me
    }

    func splitTime(with other: EventSurface, for overlap: Overlap, detaching: Bool) -> (EventSurface, EventSurface) {
        var me: EventSurface = self
        var them: EventSurface = other

        switch overlap {
        case .identical:
            let diff = endTime.value.timeIntervalSince(startTime.value)
            let midpoint = Date(timeIntervalSinceReferenceDate: startTime.value.timeIntervalSinceReferenceDate + diff/2)

            me = self.depart(at: midpoint, detaching: detaching)
            them = other.arrive(at: midpoint, detaching: detaching)

        case .staggered:
            let first = startTime.value < other.startTime.value ? self : other
            let second = first == self ? other : self
            let startOfSecond = second.startTime.value
            let endOfFirst = first.endTime.value

            guard endOfFirst < startOfSecond else { return (me, them) }

            let diff = startOfSecond.timeIntervalSince(endOfFirst)
            let midpoint = Date(timeIntervalSinceReferenceDate: endOfFirst.timeIntervalSinceReferenceDate + diff/2)

            let a = first.depart(at: midpoint, detaching: detaching)
            let b = second.arrive(at: midpoint, detaching: detaching)

            (me, them) = (first == me ? (a, b) : (b, a))

        case let .justified(direction):
            switch direction {
            case .left:
                let shorter = endTime.value < other.endTime.value ? self : other
                let longer = shorter == self ? other : self
                let amount = shorter.endTime.value.timeIntervalSince(shorter.startTime.value) / 2
                let midpoint = Date(timeIntervalSinceReferenceDate: shorter.startTime.value.timeIntervalSinceReferenceDate + amount)

                let a = shorter.depart(at: midpoint, detaching: detaching)
                let b = longer.arrive(at: midpoint, detaching: detaching)

                (me, them) = (shorter == me ? (a, b) : (b, a))

            case .right:
                let shorter = endTime.value < other.endTime.value ? self : other
                let longer = shorter == self ? other : self
                let amount = shorter.endTime.value.timeIntervalSince(shorter.startTime.value) / 2
                let midpoint = Date(timeIntervalSinceReferenceDate: shorter.startTime.value.timeIntervalSinceReferenceDate + amount)
                let a = shorter.arrive(at: midpoint, detaching: detaching)
                let b = longer.depart(at: midpoint, detaching: detaching)

                (me, them) = (shorter == me ? (a, b) : (b, a))
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

    @discardableResult
    func respond(with response: EventResponse, forceDisplay: Bool = false, detaching: Bool = false) -> EventSurface {
        var event = self
        if detaching, let recurring = self as? RecurringEventSurface {
            event = recurring.detach()!
        }
        event.userResponse.update(to: response)
        event.temporarilyForceDisplayResponseOptions = forceDisplay
        try! event.flush()
        return event
    }

    static func computeNeedsResponse(event: EventSurface) -> Bool {
        return event.userResponse.value == .none
    }

    static func computeIsConfirmed(event: EventSurface) -> Bool {
        return event.userResponse.value == .yes
    }

    static func computePerspective(fromEvent event: EventSurface) -> TimePerspective {
        return TimePerspective.forPeriod(fromStart: event.startTime.value,
                                         toEnd: event.endTime.value)
    }

    static func computeUserAttendancePerspective(fromEvent event: EventSurface) -> TimePerspective {
        return TimePerspective.forPeriod(fromStart: event.arrivalTime.value,
                                         toEnd: event.departureTime.value)
    }

    static func computeElapsed(event: EventSurface) -> Float {
        return computeElapsedBetween(start: event.startTime.value,
                                     end: event.endTime.value)
    }

    static func computeUserAttendanceElapsed(event: EventSurface) -> Float {
        return computeElapsedBetween(start: event.arrivalTime.value,
                                     end: event.departureTime.value)
    }

    private static func computeElapsedBetween(start: Date, end: Date) -> Float {
        let now = Date()

        return now.percentElapsed(withinRangeFromStart: start,
                                  toEnd: end)
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

    class func load(byId eventId: String) -> EventSurface? {
        guard let event:Event = Event.by(id: eventId) else {
            return nil
        }
        return load(with: event) as? EventSurface
    }

    static func find(bySeriesOrEventId id: String, inRange range: TimeRange) -> EventSurface? {
        return EventSurface.load(byId: id) ?? RecurringEventSurface.load(seriesId: id, in: range)
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

    func arrivesEarlier(than event: EventSurface) -> Bool {
        return arrivalTime.value < event.arrivalTime.value
    }

    func arrivesLater(than event: EventSurface) -> Bool {
        return arrivalTime.value > event.arrivalTime.value
    }

    func departsEarlier(than event: EventSurface) -> Bool {
        return departureTime.value < event.departureTime.value
    }

    func departsLater(than event: EventSurface) -> Bool {
        return departureTime.value > event.departureTime.value
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

    func formatArrivalPerspective(on day: GregorianDay?, at start: Date) -> String? {
        let calendar = Calendar.current
        if let day = day {
            let startOfDay = calendar.startOfDay(for: day)
            if start < startOfDay {
                let daysEarlier = calendar.daysBetween(start, and: startOfDay)
                switch daysEarlier {
                case 0, 1:
                    return "yesterday"

                default:
                    return "\(daysEarlier) days ago"
                }
            }
        }

        return nil
    }

    func formatDeparturePerspective(on day: GregorianDay?, at start: Date, until end: Date) -> String? {
        let calendar = Calendar.current
        if let day = day {
            let startOfDay = calendar.startOfDay(for: day)
            let endOfDay = calendar.dayAfter(startOfDay)

            if end > endOfDay {
                let daysLater = calendar.daysBetween(end, and: endOfDay)
                switch daysLater {
                case 0, 1:
                    return "tomorrow"

                default:
                    return "in \(daysLater) days"
                }
            } else if start < startOfDay {
                return "today"
            }

        } else {
            let days = calendar.daysBetween(start, and: end)
            let ess = days == 1 ? "" : "s"
            return "\(days) day\(ess) later"
        }

        return nil
    }

    func formatAttendance(viewedFrom day: GregorianDay? = nil) -> NSAttributedString {
        let start = startTime.value
        let end = endTime.value
        let arrive = arrivalTime.value
        let depart = departureTime.value

        let calendar = Calendar.current
        let startHour = calendar.component(.hour, from: start)
        let endHour = calendar.component(.hour, from: end)

        let daysBetween = calendar.daysBetween(start, and: end)
        let spansDays = daysBetween > 0
        let crossesNoon = spansDays || ( startHour < 12 && endHour >= 12 )

        let attendStartHour = calendar.component(.hour, from: arrive)
        let attendEndHour = calendar.component(.hour, from: depart)
        let attendDaysBetween = calendar.daysBetween(arrive, and: depart)
        let attendSpansDays = attendDaysBetween > 0
        let attendCrossesNoon = attendSpansDays || ( attendStartHour < 12 && attendEndHour >= 12 )

        let attendance = NSMutableAttributedString()

        let special = [NSForegroundColorAttributeName: UIColor.projectOrange]
        let normal: [String:Any] = [:]

        let fromAttributes = hasCustomArrival ? special : normal
        let from = calendar.formatDisplayTime(from: arrive, needsAMPM: attendCrossesNoon)
        attendance.append(string: from, attributes: fromAttributes)
        if attendSpansDays, let perspective = formatArrivalPerspective(on: day, at: arrive) {
            attendance.append(string: " \(perspective)", attributes: fromAttributes)
        }

        attendance.append(string: " - ", attributes: (hasCustomArrival && hasCustomDeparture ? special : normal))

        let toAttributes = hasCustomDeparture ? special : normal
        let to = calendar.formatDisplayTime(from: depart, needsAMPM: true)
        attendance.append(string: to, attributes: toAttributes)
        if attendSpansDays, let perspective = formatDeparturePerspective(on: day, at: arrive, until: depart) {
            attendance.append(string: " \(perspective)", attributes: toAttributes)
        }

        let startMovedAcrossNoon = crossesNoon != attendCrossesNoon
        let startString = calendar.formatDisplayTime(from: start, needsAMPM: (startMovedAcrossNoon || !hasCustomDeparture))
        let endString = calendar.formatDisplayTime(from: end, needsAMPM: ((attendCrossesNoon && !startMovedAcrossNoon) || !hasCustomArrival))

        if hasCustomArrival && hasCustomDeparture {
            attendance.append(string: " (\(startString)", attributes: normal)
            if calendar.areOnDifferentDays(start, arrive),
                let perspective = formatArrivalPerspective(on: day, at: start) {
                attendance.append(string: " \(perspective)", attributes: normal)
            }
            attendance.append(string: "-", attributes: normal)
            attendance.append(string: endString, attributes: normal)
            if calendar.areOnDifferentDays(end, depart),
                let perspective = formatDeparturePerspective(on: day, at: start, until: end) {
                attendance.append(string: " \(perspective)", attributes: normal)
            }
            attendance.append(string: ")", attributes: normal)

        } else if hasCustomArrival {
            attendance.append(string: " (starts \(startString)", attributes: normal)
            if calendar.areOnDifferentDays(start, arrive),
                let perspective = formatArrivalPerspective(on: day, at: start) {
                attendance.append(string: " \(perspective)", attributes: normal)
            }
            attendance.append(string: ")", attributes: normal)

        } else if hasCustomDeparture {
            attendance.append(string: " (ends \(endString)", attributes: normal)
            if calendar.areOnDifferentDays(start, arrive),
                let perspective = formatDeparturePerspective(on: day, at: start, until: end) {
                attendance.append(string: " \(perspective)", attributes: normal)
            }
            attendance.append(string: ")", attributes: normal)
        }

        return attendance
    }

    func formatDuration(viewedFrom day: GregorianDay? = nil) -> String? {
        let start = startTime.value
        let end = endTime.value

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
                let startOfDay = calendar.startOfDay(for: day)
                let endOfDay = calendar.startOfDay(for: day.dayAfter)
                if start < startOfDay {
                    let daysEarlier = calendar.daysBetween(start, and: startOfDay)
                    switch daysEarlier {
                    case 0, 1:
                        before = "(Yesterday) "
                    default:
                        before = "(\(daysEarlier) days ago) "
                    }
                }

                if end > endOfDay {
                    let daysLater = calendar.daysBetween(end, and: endOfDay)
                    switch daysLater {
                    case 0, 1:
                        after = " (Tomorrow)"
                    default:
                        after = " (in \(daysLater) days)"
                    }
                } else if start < startOfDay {
                    after = " today"
                }
            } else {
                let days = calendar.daysBetween(start, and: end)
                let ess = days == 1 ? "" : "s"
                after = " (\(days) day\(ess) later)"
            }
        }

        return "\(before)\(from) - \(to)\(after)"
    }
}



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

enum TimeConflictResolution {
    case leaveEarly
    case arriveLate
    case splitEvenly
    case decline(side: Handedness)
    case none
}

extension TimePerspective {
    // move this somewhere more appropriate?
    static func forPeriod(fromStart start: Date, toEnd end: Date) -> TimePerspective {
        let now = Date()
        if start > now {
            return .future
        } else if end < now {
            return .past
        } else {
            return .current
        }
    }
}

extension TimeRange {
    // move this somewhere more appropriate?
    var timePerspective: TimePerspective {
        return TimePerspective.forPeriod(fromStart: start,
                                         toEnd: end)
    }
}

extension EventSurface {
    func debugDo(ifTitle titleToCheck: String, block: ()->()) {
        if self.title.value == titleToCheck {
            block()
        }
    }
}
