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

class EventSurface: Surface {
    override var type: String { return "event" }

    // validation
    // change detection!! (because need to know when fields are dirty)
    // next: change this to NSObject, use KVO and 'public private (set) var xxx' for properties
    let title                  = SurfaceString(minLength: 5)
    let startTime              = SurfaceDate()
    let endTime                = SurfaceDate()
    let timeRange              = ComputedSurfaceString<EventSurface>(by: EventSurface.eventTimeRange)
    let userIgnored            = SurfaceBool()
    let userIsInvited          = SurfaceBool()
    let userInvitationResponse = SurfaceProperty<InvitationResponse>()
    let isUnresolved           = ComputedSurfaceBool<EventSurface>(by: EventSurface.computeIsUnresolved)
    let perspective            = ComputedSurfaceProperty<TimePerspective,EventSurface>(by: TimePerspective.compute)
    let percentElapsed         = ComputedSurfaceFloat<EventSurface>(by: EventSurface.computeElapsed)
    let invitationSummary      = ComputedSurfaceString<EventSurface>(by: EventSurface.formatInvitationSummary)

    /**
     * Actually ignores on the underlying event, which should propagate back up.
     */
    func ignore() {
        guard let bridge = self.store as? SurfaceBridge,
            let event = bridge.dereference("event") as? Event else {
            fatalError("No backing bridge")
        }
        if Ignorance.ignore(event, for: event.me!.person!) {
            self.notifyObserversOfChange() // because the Ignorance model isn't referenced
        }
    }

    func stopIgnoring() {
        if let bridge = self.store as? SurfaceBridge,
            let event = bridge.dereference("event") as? Event,
            let ignorance = Ignorance.of(event, by: event.me!.person!) {
            ignorance.delete()
            self.notifyObserversOfChange()
        }
    }

    static func computeIsUnresolved(event: EventSurface) -> Bool {
        if event.userIsInvited.value, event.userInvitationResponse.value == .none {
            return true
        } else {
            return false
        }
    }

    static func eventTimeRange(event: EventSurface) -> String {
        return "10am-2pm" // TODO: actually do this
    }

    static func computeElapsed(event: EventSurface) -> Float {
        return 0.0 // TODO: calcualte elapsed time
    }

    static func formatInvitationSummary(event: EventSurface) -> String {
        return "" // TODO: format Invitation Summary
    }

    static func load(eventId: String) -> EventSurface? {
        guard let event:Event = Event.by(id: eventId) else {
            return nil
        }

        let surface = EventSurface(id: eventId)
        let bridge = SurfaceBridge(id: eventId)
        bridge.reference(event, as: "event")
        bridge.bindAll(surface.title, surface.startTime, surface.endTime)
        bridge.readonlyBind(surface.userIgnored) { (model:LeapModel) in
            guard let thing = model as? Temporality, let me = thing.me else {
                return false
            }
            if let _ = Ignorance.of(thing, by: me.person!) {
                return true
            }
            return false
        }
        bridge.readonlyBind(surface.userIsInvited) { (model:LeapModel) in
            guard let thing = model as? Temporality, let me = thing.me else {
                return false
            }
            return me.ownership == .invitee
        }
        surface.store = bridge
        surface.populate()
        return surface
    }
}
