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

enum TimePerspective {
    case past,
    future,
    current

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

func timeRangeString(fromDate date: Date) -> String {
    return ""
}

func eventTimeRange(event: EventShell) -> String {
    return "10am-2pm" // TODO: actually do this
}

func computeElapsed(event: EventShell) -> Float {
    return 0.0 // TODO: calcualte elapsed time
}

class EventShell: Shell {
    static let schema = Schema(type: "event",
                               properties: [WritableProperty<String>("title", validatedBy: validIfAtLeast(characters: 5)),
                                            WritableProperty<Date>("start_time"),
                                            WritableProperty<Date>("end_time"),
                                            ComputedProperty<String,EventShell>("time_range", eventTimeRange),
                                            WritableProperty<Bool>("ignored", defaultingTo: false),
                                            WritableProperty<InvitationResponse>("response", defaultingTo: .none),
                                            ComputedProperty<Bool,EventShell>("unresolved", {event in
                                                if event.userIsInvited.value, event.userInvitationResponse.value == .none {
                                                    return true
                                                } else {
                                                    return false
                                                }
                                            }),
                                            ComputedProperty<TimePerspective,EventShell>("perspective", TimePerspective.compute),
                                            ComputedProperty<Float,EventShell>("elapsed", computeElapsed)])

    var title:                  WritableProperty<String>             { return writable("title") }
    var startTime:              WritableProperty<Date>               { return writable("start_time") }
    var endTime:                WritableProperty<Date>               { return writable("end_time") }
    var timeRange:              ReadableProperty<String>             { return property("time_range") }
    var userIgnored:            WritableProperty<Bool>               { return writable("ignored") }
    var userIsInvited:          ReadableProperty<Bool>               { return property("invited") }
    var userInvitationResponse: WritableProperty<InvitationResponse> { return writable("response") }
    var isUnresolved:           ReadableProperty<Bool>               { return property("unresolved") }
    var happeningIn:            ReadableProperty<TimePerspective>    { return property("perspective") }
    var percentElapsed:         ReadableProperty<Float>              { return property("elapsed") }

    init(id: String, data: [String:Any]) {
        super.init(schema: EventShell.schema, id: id, data: data)
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
