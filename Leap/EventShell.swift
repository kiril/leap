//
//  EventRepresentation.swift
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
    static func compute(fromEvent event: EventShell) -> TimePerspective {
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

func eventTimeRange(event: EventShell) -> String {
    return "10am-2pm" // TODO: actually do this
}

func computeElapsed(event: EventShell) -> Float {
    return 0.0 // TODO: calcualte elapsed time
}


class EventShell: Shell {
    let title =                  WritableProperty<String>("title", validatedBy: validIfAtLeast(characters: 5))
    let startTime =              WritableProperty<Date>("start_time")
    let endTime =                WritableProperty<Date>("end_time")
    let timeRange =              ComputedProperty<String,EventShell>("time_range", eventTimeRange)
    let userIgnored =            WritableProperty<Bool>("ignored", defaultingTo: false)
    let userIsInvited =          ReadableProperty<Bool>("invited", defaultingTo: false)
    let userInvitationResponse = WritableProperty<InvitationResponse>("response", defaultingTo: .none)
    let isUnresolved =           ComputedProperty<Bool,EventShell>("unresolved", {event in
        if event.userIsInvited.value, event.userInvitationResponse.value == .none {
            return true
        } else {
            return false
        }
    })
    let userPerspective =        ComputedProperty<TimePerspective,EventShell>("perspective", TimePerspective.compute)
    let percentElapsed =         ComputedProperty<Float,EventShell>("elapsed", computeElapsed)


    init(id: String, data: [String:Any]) {
        super.init(type: "event", id: id, data: data)
    }
}

// var event = EventRepresentation.find(byId: "klsdhfgaoiusghdpoiuhy")
// var event = EventRepresentation.new()
// label.text = event.title.string
// event.title.update(to: "New Title", via: self)
//
// "don't notify" is a thing, as might be "notify me of my own change"
// don't include source if you're fine getting your own update
// update(to: <T>)
// updateSilently(to: <T>)
// timeRange => a computed non-mutable ComputedField<T> property
