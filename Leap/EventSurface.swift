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

        let surface = EventSurface(id: event.id)
        surface.reference(event, as: "event")
        surface.bindAll(surface.title, surface.startTime, surface.endTime) // these are all default-bound to identical fields in the model
        surface.bind(surface.userIgnored)
        surface.bind(surface.userIsInvited)
        return surface
    }
}
