//
//  EventRepresentation.swift
//  Leap
//
//  Created by Kiril Savino on 3/19/17.
//  Copyright © 2017 Single Leap, Inc. All rights reserved.
//


func validTimeString(value: String) -> Bool {
    return true
}

class EventRepresentation: Representation {
    static let schema = Schema(type: "event",
                               properties: [WritableProperty<String>("title", validatedBy: validIfAtLeast(characters: 5)),
                                            WritableProperty<String>("start_time", validatedBy: validTimeString),
                                            WritableProperty<String>("end_time", validatedBy: validTimeString),
                                            ComputedProperty<String>("time_range", getter: {(representation) in return ""})])

    var title:     WritableProperty<String> { return writable("title") }
    var startTime: WritableProperty<String> { return writable("start_time") }
    var endTime:   WritableProperty<String> { return writable("end_time") }
    var timeRange: ReadableProperty<String> { return property("time_range") }

    init(id: String, data: [String:Any]) {
        super.init(schema: EventRepresentation.schema, id: id, data: data)
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
