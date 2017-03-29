//
//  Property.swift
//  Leap
//
//  Created by Kiril Savino on 3/20/17.
//  Copyright © 2017 Single Leap, Inc. All rights reserved.
//

import Foundation


protocol Property {
    var name: String { get }
    var surface: Surface? { get set }
    var surfaceType: String { get }
    var stringValue: String { get }

    func copyReferencing(_ surface: Surface) -> Property
    func isValid(value: Any) -> Bool
}


protocol TypedProperty: Property {
    associatedtype Value

    var value: Value { get }
    var rawValue: Value? { get }
}


protocol Writable {
}


protocol WritableTypedProperty: TypedProperty, Writable {
    func update(to value: Value, via source: SourceIdentifiable?) throws
    func update(to value: Value, silently: Bool) throws
    func clear(via source: SourceIdentifiable) throws
    func clear(silently: Bool) throws
}

extension String {
    init(_ property: Property) {
        self.init(property.stringValue)!
    }
}


public class ReadableProperty<T>: TypedProperty {
    let key: String
    let validator: Validator<T>
    weak var surface: Surface?

    private let _defaultDefaults: [Any] = ["", Int(0), Float(0.0), false]

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
    var value: T { return surface!.data[self.key] as? T ?? defaultValue! }
    var rawValue: T? { return surface!.data[self.key] as? T }
    var surfaceType: String { return surface!.type }

    var stringValue: String { return value as? String ?? "\(value)" }

    init(_ key: String, validatedBy validator: @escaping Validator<T>, defaultingTo defaultValue: T?, referencing surface: Surface?) {
        self.key = key
        self.validator = validator
        self.surface = surface
        self.defaultValue = defaultValue
    }

    convenience init(_ key: String, validatedBy validator: @escaping Validator<T>) {
        self.init(key, validatedBy: validator, defaultingTo: nil, referencing: nil)
    }

    convenience init(_ key: String, defaultingTo defaultValue: T? = nil) {
        self.init(key, validatedBy: alwaysValid, defaultingTo: defaultValue, referencing: nil)
    }

    convenience init(_ key: String, referencing surface: Surface) {
        self.init(key, validatedBy: alwaysValid, defaultingTo: nil, referencing: surface)
    }

    func isValid(value: Any) -> Bool {
        guard value is T else {
            return false
        }
        return self.validator(value as! T)
    }

    func copyReferencing(_ surface: Surface) -> Property {
        return ReadableProperty(key, validatedBy: validator, defaultingTo: _customDefault, referencing: surface)
    }
}


public class WritableProperty<T>: ReadableProperty<T>, WritableTypedProperty {

    convenience init(_ key: String, validatedBy validator: @escaping Validator<T>) {
        self.init(key, validatedBy: validator, defaultingTo: nil, referencing: nil)
    }

    convenience init(_ key: String, validatedBy validator: @escaping Validator<T>, referencing surface: Surface) {
        self.init(key, validatedBy: validator, defaultingTo: nil, referencing: surface)
    }

    func update(to value: T, via source: SourceIdentifiable?) throws {
        try surface!.update(key: self.key, toValue: value, via: source)
    }

    func update(to value: T, silently: Bool = false) throws {
        try surface!.update(key: self.key, toValue: value, via: nil, silently: silently)
    }

    func clear(via source: SourceIdentifiable) throws {
        surface!.remove(key: self.key, via: source)
    }

    func clear(silently: Bool = false) throws {
        surface!.remove(key: self.key, via: nil, silently: silently)
    }

    override func copyReferencing(_ surface: Surface) -> Property {
        return WritableProperty(key, validatedBy: self.validator, defaultingTo: _customDefault, referencing: surface)
    }
}

typealias Computation<T,R:Surface> = (R) -> T

public class ComputedProperty<T,R:Surface>: ReadableProperty<T> {
    internal let getter: Computation<T,R>

    override var value: T {
        if let mockValue = surface!.mockData?[key] as? T {
            return mockValue
        }
        return getter(surface as! R)
    }

    override func isValid(value: Any) -> Bool {
        return false
    }

    init(_ key: String, _ getter: @escaping Computation<T,R>, referencing surface: Surface?) {
        self.getter = getter
        super.init(key, validatedBy: alwaysValid, defaultingTo: nil, referencing: surface)
    }

    convenience init(_ key: String, _ getter: @escaping Computation<T,R> ) {
        self.init(key, getter, referencing: nil)
    }

    override func copyReferencing(_ surface: Surface) -> Property {
        return ComputedProperty(key, getter, referencing: surface)
    }
}
