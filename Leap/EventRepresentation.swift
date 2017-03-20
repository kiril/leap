//
//  EventRepresentation.swift
//  Leap
//
//  Created by Kiril Savino on 3/19/17.
//  Copyright © 2017 Single Leap, Inc. All rights reserved.
//


let eventSchema = Schema(type: "event",
                         fields: [Field(key: "id", validator: alwaysValid),
                                  MutableField(key: "title", validator: validIfAtLeast(characters: 5))])

class EventRepresentation: Representation {
    let title: Field

    override init(schema: Schema, id: String, data: [String:Any]) {
        title = schema.field("title")!
        super.init(schema: schema, id: id, data: data)
    }
}
