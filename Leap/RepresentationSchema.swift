//
//  RepresentationSchema.swift
//  Leap
//
//  Created by Kiril Savino on 3/19/17.
//  Copyright © 2017 Single Leap, Inc. All rights reserved.
//


enum SchemaError: Error {
    case fieldNotMutable(type: String, field: String)
    case invalidValueForField(type: String, field: String, value: Any)
    case noSuchField(type: String, field: String)
}


struct Schema {
    let type: String
    let fields: [Field]

    init(type: String, fields: [Field]) {
        self.type = type
        self.fields = fields
    }

    func field(_ name: String) -> Field? {
        for field in fields {
            if field.name == name {
                return field
            }
        }
        return nil
    }

    func fieldMap(for representation: Representation) -> [String:Field] {
        let adapted = fields.map { $0.copyReferencing(representation) }
        var map = [String:Field]()
        for field in adapted {
            map[field.name] = field
        }
        return map
    }
}
