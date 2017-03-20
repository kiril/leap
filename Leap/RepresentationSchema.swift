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


class Field {
    let key: String
    let validator: FieldValidator
    internal weak var representation: Representation?
    var defaultString: String = ""
    var defaultInt: Int = 0
    var defaultFloat: Float = 0.0

    var value: Any? {
        return representation!.data[self.key]
    }

    var type: String {
        return representation!.type
    }

    var string: String { return value as? String ?? defaultString }
    var int: Int { return value as? Int ?? defaultInt }
    var float: Float { return value as? Float ?? defaultFloat }

    init(key: String, validator: @escaping FieldValidator) {
        self.key = key
        self.validator = validator
    }

    func update(to value: Any, via source: SourceIdentifiable) throws {
        guard self is MutableField else {
            throw SchemaError.fieldNotMutable(type: type, field: self.key)
        }
        guard validator(value) else {
            throw SchemaError.invalidValueForField(type: type, field: self.key, value: value)
        }
        representation!.update(field: self.key, toValue: value, via: source)
    }

    func clear(via source: SourceIdentifiable) throws {
        guard self is MutableField else {
            throw SchemaError.fieldNotMutable(type: type, field: self.key)
        }
        representation!.remove(field: self.key, via: source)
    }

    func copyFor(representation: Representation) -> Field {
        let copy = Field(key: self.key, validator: self.validator)
        copy.representation = representation
        return copy
    }
}


class MutableField: Field {
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
            if field.key == name {
                return field
            }
        }
        return nil
    }

    func fieldMap(for representation: Representation) -> [String:Field] {
        let adapted = fields.map { $0.copyFor(representation: representation) }
        var map = [String:Field]()
        for field in adapted {
            map[field.key] = field
        }
        return map
    }
}
