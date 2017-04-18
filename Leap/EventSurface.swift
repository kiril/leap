//
//  EventSurface.swift
//  Leap
//
//  Created by Kiril Savino on 3/19/17.
//  Copyright © 2017 Single Leap, Inc. All rights reserved.
//


import Foundation


enum InvitationResponse {
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
    let userIgnored            = SurfaceBool()
    let userIsInvited          = SurfaceBool()
    let userInvitationResponse = SurfaceProperty<InvitationResponse>()
    let needsResponse          = ComputedSurfaceBool<EventSurface>(by: EventSurface.computeNeedsResponse)
    let isConfirmed            = ComputedSurfaceBool<EventSurface>(by: EventSurface.computeIsConfirmed)
    let perspective            = ComputedSurfaceProperty<TimePerspective,EventSurface>(by: TimePerspective.compute)
    let percentElapsed         = ComputedSurfaceFloat<EventSurface>(by: EventSurface.computeElapsed)
    let invitationSummary      = ComputedSurfaceString<EventSurface>(by: EventSurface.formatInvitationSummary)
    let isRecurring            = SurfaceBool()

    /**
     * Actually ignores on the underlying event, which should propagate back up.
     */
    func ignore() {
        guard let bridge = self.store as? SurfaceModelBridge,
            let event = bridge.dereference("event") as? Event else {
            fatalError("No backing bridge")
        }
        if Ignorance.ignore(event, for: event.me!.person!) {
            self.notifyObserversOfChange() // because the Ignorance model isn't referenced
        }
    }

    func stopIgnoring() {
        if let bridge = self.store as? SurfaceModelBridge,
            let event = bridge.dereference("event") as? Event,
            let ignorance = Ignorance.of(event, by: event.me!.person!) {
            ignorance.delete()
            self.notifyObserversOfChange()
        }
    }

    static func computeNeedsResponse(event: EventSurface) -> Bool {
        if event.userIsInvited.value, event.userInvitationResponse.value == .none {
            return true
        } else {
            return false
        }
    }

    static func computeIsConfirmed(event: EventSurface) -> Bool {
        if event.userInvitationResponse.value == .yes {
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

        func getUserIgnored(model:LeapModel) -> Any? {
            guard let thing = model as? Temporality, let me = thing.me else {
                return false
            }
            if let _ = Ignorance.of(thing, by: me.person!) {
                return true
            }
            return false
        }
        func setUserIgnored(model:LeapModel, value: Any?) {
            guard   let thing = model as? Temporality,
                    let me = thing.me,
                    let ignore = value as? Bool else {
                fatalError("OMG wrong type or something \(model)")
            }

            if ignore {
                Ignorance.ignore(thing, for: me.person!)
            } else {
                Ignorance.unignore(thing, for: me.person!)
            }
        }
        bridge.bind(surface.userIgnored, populateWith: getUserIgnored, on: "event", persistWith: setUserIgnored)

        bridge.readonlyBind(surface.userIsInvited) { (model:LeapModel) in
            guard let thing = model as? Temporality, let me = thing.me else {
                return false
            }
            return me.ownership == .invitee
        }

        func getInvitationResponse(model:LeapModel) -> Any? {
            guard let thing = model as? Temporality, let me = thing.me else {
                return InvitationResponse.none
            }
            switch me.engagement {
            case .undecided, .none:
                return InvitationResponse.none
            case .engaged:
                return InvitationResponse.yes
            case .disengaged:
                return InvitationResponse.no
            case .tracking:
                return InvitationResponse.maybe
            }
        }
        func setInvitationResponse(model:LeapModel, value: Any?) {
            guard   let thing = model as? Temporality,
                    let me = thing.me,
                    let response = value as? InvitationResponse else {
                fatalError("OMG wrong type or something \(model)")
                // could this happen just because you are no longer invited?
            }

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
        bridge.bind(surface.userInvitationResponse,
                    populateWith: getInvitationResponse,
                    on: "event",
                    persistWith: setInvitationResponse)

        surface.store = bridge
        bridge.populate(surface)
        return surface
    }
}
