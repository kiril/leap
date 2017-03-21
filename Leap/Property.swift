//
//  RepresentationField.swift
//  Leap
//
//  Created by Kiril Savino on 3/20/17.
//  Copyright © 2017 Single Leap, Inc. All rights reserved.
//

import Foundation


protocol Property {
    var name: String { get }
    var representationType: String { get }
    var stringValue: String { get }

    func copyReferencing(_ representation: Representation) -> Property
    func isValid(value: Any) -> Bool
}


protocol TypedProperty: Property {
    associatedtype Value

    var value: Value? { get }
    var rawValue: Value? { get }
}


protocol WritableTypedProperty: TypedProperty {
    func update(to value: Value, via source: SourceIdentifiable) throws
    func update(to value: Value, silently: Bool) throws
    func clear(via source: SourceIdentifiable) throws
    func clear(silently: Bool) throws
}


public class ReadableProperty<T>: TypedProperty {
    let key: String
    let validator: Validator<T>
    internal weak var representation: Representation?

    private let _defaultDefaults: [Any] = ["", Int(0), Float(0.0)]

    func _defaultDefault() -> T? {
        for aDefault in _defaultDefaults {
            switch aDefault {
            case let typeMatchedDefault as T:
                return typeMatchedDefault
            default:
                continue
            }
        }
        return nil
    }

    var _customDefault: T?

    var defaultValue: T? {
        get {
            if let customDefault = _customDefault {
                return customDefault
            }
            return _defaultDefault()
        }
        set (customDefault) {
            _customDefault = customDefault
        }
    }

    var name: String { return key }
    var value: T? { return representation!.data[self.key] as? T ?? defaultValue }
    var rawValue: T? { return representation!.data[self.key] as? T }
    var representationType: String { return representation!.type }

    var stringValue: String { if let value = self.value { return value as? String ?? "\(value)" }; return "\(defaultValue)" }

    init(_ key: String, validatedBy validator: @escaping Validator<T>, defaultingTo defaultValue: T?, referencing representation: Representation?) {
        self.key = key
        self.validator = validator
        self.representation = representation
        self.defaultValue = defaultValue
    }

    convenience init(_ key: String, validatedBy validator: @escaping Validator<T>) {
        self.init(key, validatedBy: validator, defaultingTo: nil, referencing: nil)
    }

    convenience init(_ key: String, defaultingTo defaultValue: T? = nil) {
        self.init(key, validatedBy: alwaysValid, defaultingTo: defaultValue, referencing: nil)
    }

    convenience init(_ key: String, referencing representation: Representation) {
        self.init(key, validatedBy: alwaysValid, defaultingTo: nil, referencing: representation)
    }


    func isValid(value: Any) -> Bool {
        guard value is T else {
            return false
        }
        return self.validator(value as! T)
    }

    func copyReferencing(_ representation: Representation) -> Property {
        return ReadableProperty(key, validatedBy: validator, defaultingTo: _customDefault, referencing: representation)
    }
}


public class WritableProperty<T>: ReadableProperty<T> {

    convenience init(_ key: String, validatedBy validator: @escaping Validator<T>) {
        self.init(key, validatedBy: validator, defaultingTo: nil, referencing: nil)
    }

    func update(to value: T, via source: SourceIdentifiable?) throws {
        try representation!.update(key: self.key, toValue: value, via: source)
    }

    func update(to value: T, silently: Bool = false) throws {
        try representation!.update(key: self.key, toValue: value, via: nil, silently: silently)
    }

    func clear(via source: SourceIdentifiable) throws {
        representation!.remove(key: self.key, via: source)
    }

    func clear(silently: Bool = false) throws {
        representation!.remove(key: self.key, via: nil, silently: silently)
    }

    override func copyReferencing(_ representation: Representation) -> Property {
        return WritableProperty(key, validatedBy: self.validator, defaultingTo: _customDefault, referencing: representation)
    }
}

typealias Computation<T> = (Representation) -> T

public class ComputedProperty<T>: ReadableProperty<T> {
    internal let getter: Computation<T>

    override var value: T? {
        return getter(representation!)
    }


    init(_ key: String, getter: @escaping Computation<T>, referencing representation: Representation?) {
        self.getter = getter
        super.init(key, validatedBy: alwaysValid, defaultingTo: nil, referencing: representation)
    }

    convenience init(_ key: String, getter: @escaping Computation<T> ) {
        self.init(key, getter: getter, referencing: nil)
    }

    override func copyReferencing(_ representation: Representation) -> Property {
        return ComputedProperty(key, getter: getter, referencing: representation)
    }
}
