//
//  Property.swift
//  Leap
//
//  Created by Kiril Savino on 3/20/17.
//  Copyright © 2017 Single Leap, Inc. All rights reserved.
//

import Foundation


protocol Property {
    var key: String { get }
    var hasKey: Bool { get }
    var surface: Surface? { get set }
    var surfaceType: String { get }
    var stringValue: String { get }

    func copyReferencing(_ surface: Surface) -> Property
    func isValid(value: Any) -> Bool
    func setKey(_ key: String)
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
    var _key: String?
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

    var key: String { return _key! }
    var value: T {
        return surface!.getValue(for: key) as? T ?? defaultValue!
    }
    var rawValue: T? { return surface!.getValue(for: key) as? T }
    var surfaceType: String { return surface!.type }

    var stringValue: String { return value as? String ?? "\(value)" }

    init(_ key: String?, validatedBy validator: @escaping Validator<T> = alwaysValid, defaultingTo defaultValue: T? = nil, referencing surface: Surface? = nil) {
        _key = key
        self.validator = validator
        self.surface = surface
        self.defaultValue = defaultValue
    }

    func setKey(_ key: String) {
        _key = key
    }

    var hasKey: Bool {
        return _key != nil
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

    func update(to value: T, via source: SourceIdentifiable?) {
        try! surface!.update(key: key, toValue: value, via: source)
    }

    func update(to value: T, silently: Bool = false) {
        try! surface!.update(key: key, toValue: value, via: nil, silently: silently)
    }

    func clear(via source: SourceIdentifiable) throws {
        surface!.remove(key: key, via: source)
    }

    func clear(silently: Bool = false) throws {
        surface!.remove(key: key, via: nil, silently: silently)
    }

    override func copyReferencing(_ surface: Surface) -> Property {
        return WritableProperty(key, validatedBy: self.validator, defaultingTo: _customDefault, referencing: surface)
    }
}

typealias Computation<T,R:Surface> = (R) -> T

public class ComputedProperty<T,R:Surface>: ReadableProperty<T> {
    internal let getter: Computation<T,R>

    override var value: T {
        return surface!.mockValue(for: key) ?? getter(surface as! R)
    }

    override func isValid(value: Any) -> Bool {
        return false
    }

    init(_ key: String?, _ getter: @escaping Computation<T,R>, referencing surface: Surface?) {
        self.getter = getter
        super.init(key, validatedBy: alwaysValid, defaultingTo: nil, referencing: surface)
    }

    convenience init(_ key: String?, _ getter: @escaping Computation<T,R> ) {
        self.init(key, getter, referencing: nil)
    }

    override func copyReferencing(_ surface: Surface) -> Property {
        return ComputedProperty(key, getter, referencing: surface)
    }
}
