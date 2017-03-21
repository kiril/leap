//
//  Schema.swift
//  Leap
//
//  Created by Kiril Savino on 3/19/17.
//  Copyright © 2017 Single Leap, Inc. All rights reserved.
//


public enum SchemaError: Error {
    case notWritable(type: String, property: String)
    case invalidValueFor(type: String, property: String, value: Any)
    case noSuch(type: String, property: String)
}


struct Schema {
    let type: String
    let properties: [Property]

    init(type: String, properties: [Property]) {
        self.type = type
        self.properties = properties
    }

    func field(_ name: String) -> Property? {
        for property in properties {
            if property.name == name {
                return property
            }
        }
        return nil
    }

    func map(for shell: Shell) -> [String:Property] {
        let adapted = properties.map { $0.copyReferencing(shell) }
        var d = [String:Property]()
        for property in adapted {
            d[property.name] = property
        }
        return d
    }
}
