//
//  RepresentationSchema.swift
//  Leap
//
//  Created by Kiril Savino on 3/19/17.
//  Copyright © 2017 Single Leap, Inc. All rights reserved.
//


enum RepresentationSchemaError: Error {
    case fieldNotMutable(type: String, field: String)
    case invalidValueForField(type: String, field: String, value: Any)
    case noSuchField(type: String, field: String)
}


class RepresentationField {
    let key: String
    let validator: RepresentationFieldValidator
    internal weak var representation: Representation?
    var defaultString: String = ""
    var defaultInt: Int = 0
    var defaultFloat: Float = 0.0

    var value: Any? {
        return representation!.data[self.key]
    }

    var string: String { return value as? String ?? defaultString }
    var int: Int { return value as? Int ?? defaultInt }
    var float: Float { return value as? Float ?? defaultFloat }

    init(key: String, validator: @escaping RepresentationFieldValidator) {
        self.key = key
        self.validator = validator
    }

    func update(to value: Any, via source: SourceIdentifiable) throws {
        guard self is MutableRepresentationField else {
            throw RepresentationSchemaError.fieldNotMutable(type: representation!.type, field: self.key)
        }
        representation!.update(field: self.key, toValue: value, via: source)
    }

    func clear(via source: SourceIdentifiable) throws {
        guard self is MutableRepresentationField else {
            throw RepresentationSchemaError.fieldNotMutable(type: representation!.type, field: self.key)
        }
        representation!.remove(field: self.key, via: source)
    }

    func copyFor(representation: Representation) -> RepresentationField {
        let copy = RepresentationField(key: self.key, validator: self.validator)
        copy.representation = representation
        return copy
    }
}


class MutableRepresentationField: RepresentationField {
}


class RepresentationSchema {
    let fields: [RepresentationField]
    internal let fieldNames: Set<String>

    init(fields: [RepresentationField]) {
        self.fields = fields
        self.fieldNames = Set(fields.map {$0.key})
    }

    func hasField(field: String) -> Bool {
        return self.fieldNames.contains(field)
    }

    func copyFor(representation: Representation) -> RepresentationSchema {
        return RepresentationSchema(fields: fields.map { $0.copyFor(representation: representation) })
    }
}
