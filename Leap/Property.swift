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
    var shell: Shell? { get set }
    var shellType: String { get }
    var stringValue: String { get }

    func copyReferencing(_ shell: Shell) -> Property
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
    weak var shell: Shell?

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
    var value: T { return shell!.data[self.key] as? T ?? defaultValue! }
    var rawValue: T? { return shell!.data[self.key] as? T }
    var shellType: String { return shell!.type }

    var stringValue: String { return value as? String ?? "\(value)" }

    init(_ key: String, validatedBy validator: @escaping Validator<T>, defaultingTo defaultValue: T?, referencing shell: Shell?) {
        self.key = key
        self.validator = validator
        self.shell = shell
        self.defaultValue = defaultValue
    }

    convenience init(_ key: String, validatedBy validator: @escaping Validator<T>) {
        self.init(key, validatedBy: validator, defaultingTo: nil, referencing: nil)
    }

    convenience init(_ key: String, defaultingTo defaultValue: T? = nil) {
        self.init(key, validatedBy: alwaysValid, defaultingTo: defaultValue, referencing: nil)
    }

    convenience init(_ key: String, referencing shell: Shell) {
        self.init(key, validatedBy: alwaysValid, defaultingTo: nil, referencing: shell)
    }


    func isValid(value: Any) -> Bool {
        guard value is T else {
            return false
        }
        return self.validator(value as! T)
    }

    func copyReferencing(_ shell: Shell) -> Property {
        return ReadableProperty(key, validatedBy: validator, defaultingTo: _customDefault, referencing: shell)
    }
}


public class WritableProperty<T>: ReadableProperty<T>, WritableTypedProperty {

    convenience init(_ key: String, validatedBy validator: @escaping Validator<T>) {
        self.init(key, validatedBy: validator, defaultingTo: nil, referencing: nil)
    }

    convenience init(_ key: String, validatedBy validator: @escaping Validator<T>, referencing shell: Shell) {
        self.init(key, validatedBy: validator, defaultingTo: nil, referencing: shell)
    }

    func update(to value: T, via source: SourceIdentifiable?) throws {
        try shell!.update(key: self.key, toValue: value, via: source)
    }

    func update(to value: T, silently: Bool = false) throws {
        try shell!.update(key: self.key, toValue: value, via: nil, silently: silently)
    }

    func clear(via source: SourceIdentifiable) throws {
        shell!.remove(key: self.key, via: source)
    }

    func clear(silently: Bool = false) throws {
        shell!.remove(key: self.key, via: nil, silently: silently)
    }

    override func copyReferencing(_ shell: Shell) -> Property {
        return WritableProperty(key, validatedBy: self.validator, defaultingTo: _customDefault, referencing: shell)
    }
}

typealias Computation<T,R:Shell> = (R) -> T

public class ComputedProperty<T,R:Shell>: ReadableProperty<T> {
    internal let getter: Computation<T,R>

    override var value: T {
        return getter(shell as! R)
    }

    override func isValid(value: Any) -> Bool {
        return false
    }

    init(_ key: String, _ getter: @escaping Computation<T,R>, referencing shell: Shell?) {
        self.getter = getter
        super.init(key, validatedBy: alwaysValid, defaultingTo: nil, referencing: shell)
    }

    convenience init(_ key: String, _ getter: @escaping Computation<T,R> ) {
        self.init(key, getter, referencing: nil)
    }

    override func copyReferencing(_ shell: Shell) -> Property {
        return ComputedProperty(key, getter, referencing: shell)
    }
}
