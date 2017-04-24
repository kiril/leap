//
//  EventSurface.swift
//  Leap
//
//  Created by Kiril Savino on 3/19/17.
//  Copyright © 2017 Single Leap, Inc. All rights reserved.
//


import Foundation


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

    // validation
    // change detection!! (because need to know when fields are dirty)
    // next: change this to NSObject, use KVO and 'public private (set) var xxx' for properties
    let title                  = SurfaceString(minLength: 1)
    let startTime              = SurfaceDate()
    let endTime                = SurfaceDate()
    let timeRange              = ComputedSurfaceString<EventSurface>(by: EventSurface.eventTimeRange)
    let userIsInvited          = SurfaceBool()
    let userResponse           = SurfaceProperty<EventResponse>()
    let needsResponse          = ComputedSurfaceBool<EventSurface>(by: EventSurface.computeNeedsResponse)
    let isConfirmed            = ComputedSurfaceBool<EventSurface>(by: EventSurface.computeIsConfirmed)
    let perspective            = ComputedSurfaceProperty<TimePerspective,EventSurface>(by: TimePerspective.compute)
    let percentElapsed         = ComputedSurfaceFloat<EventSurface>(by: EventSurface.computeElapsed)
    let invitationSummary      = SurfaceString()
    let isRecurring            = SurfaceBool()
    let origin                 = SurfaceProperty<Origin>()

    /**
     * Actually ignores on the underlying event, which should propagate back up.
     */
    func ignore() {
        guard let bridge = self.store as? SurfaceModelBridge,
            let event = bridge.dereference("event") as? Event else {
            fatalError("No backing bridge")
        }
        if Ignorance.ignore(event) {
            self.notifyObserversOfChange() // because the Ignorance model isn't referenced
        }
    }

    func stopIgnoring() {
        if let bridge = self.store as? SurfaceModelBridge,
            let event = bridge.dereference("event") as? Event,
            let ignorance = Ignorance.of(event) {
            ignorance.delete()
            self.notifyObserversOfChange()
        }
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

        return "\(from)-\(to)\(more)"
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

    static func formatInvitationSummary(event: EventSurface) -> String {
        return "" // TODO: format Invitation Summary
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

        bridge.readonlyBind(surface.invitationSummary) { (model:LeapModel) -> String? in
            let someone = "Someone"
            let someCalendar = "Shared Calendar"
            if let event = model as? Event {
                switch event.origin {
                case .share:
                    if let link = event.links.first, let organizer = event.organizer {
                        return "\(organizer.nameOrEmail) -> \(link.calendar!.title)"
                    } else if let organizer = event.organizer {
                        return "from \(organizer.nameOrEmail)"
                    } else if let link = event.links.first {
                        return "via \(link.calendar?.title ?? someCalendar)"
                    }
                    return "via Shared Calendar"

                case .invite:
                    let from = event.organizer?.name ?? someone
                    var to = ""

                    for participant in event.invitees {
                        let name = participant.isMe ? "Me" : participant.nameOrEmail
                        if !to.characters.isEmpty {
                            to += ", "
                        }
                        to += name
                    }
                    if to.characters.isEmpty {
                        to = "Unknown Invitees"
                    }

                    return "\(from) -> \(to)"

                case .subscription:
                    return "via \(event.links.first?.calendar!.title ?? someCalendar)"

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
