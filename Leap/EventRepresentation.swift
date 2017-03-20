//
//  EventRepresentation.swift
//  Leap
//
//  Created by Kiril Savino on 3/19/17.
//  Copyright © 2017 Single Leap, Inc. All rights reserved.
//


let validTimeString: (Any) -> Bool = { value in
    return true
}

let eventSchema = Schema(type: "event",
                         fields: [Field(key: "id", validator: alwaysValid),
                                  MutableField(key: "title", validator: validIfAtLeast(characters: 5)),
                                  MutableField(key: "start_time", validator: validTimeString),
                                  MutableField(key: "end_time", validator: validTimeString)])

class EventRepresentation: Representation {
    let title: Field
    let startTime: Field
    let endTime: Field

    override init(schema: Schema, id: String, data: [String:Any]) {
        title = schema.field("title")!
        startTime = schema.field("start_time")!
        endTime = schema.field("end_time")!
        super.init(schema: schema, id: id, data: data)
    }
}
