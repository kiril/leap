//
//  RepresentationField.swift
//  Leap
//
//  Created by Kiril Savino on 3/20/17.
//  Copyright © 2017 Single Leap, Inc. All rights reserved.
//

import Foundation


protocol FieldUsable {}

extension String: FieldUsable {}
extension Int: FieldUsable {}
extension Float: FieldUsable {}
extension NSDate: FieldUsable {}


protocol Field {
    var name: String { get }
    var representationType: String { get }
    var stringValue: String { get }

    func copyReferencing(_ representation: Representation) -> Field
    func isValid(value: Any) -> Bool
}


protocol TypedField: Field {
    associatedtype Value: FieldUsable

    var value: Value? { get }
    var rawValue: Value? { get }

    func update(to value: Value, via source: SourceIdentifiable) throws
    func update(to value: Value, silently: Bool) throws
    func clear(via source: SourceIdentifiable) throws
    func clear(silently: Bool) throws
}


class FieldBase<T:FieldUsable>: TypedField {
    let key: String
    let validator: FieldValidator<T>
    internal weak var representation: Representation?

    private let _defaultDefaults: [FieldUsable] = ["", Int(0), Float(0.0)]

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

    var name: String {
        return key
    }

    var value: T? {
        return representation!.data[self.key] as? T ?? defaultValue
    }

    var rawValue: T? {
        return representation!.data[self.key] as? T
    }

    var stringValue: String {
        if let value = self.value {
            if value is String {
                return value as! String
            }
            return "\(value)"
        }
        return "\(defaultValue)"
    }

    var representationType: String {
        return representation!.type
    }

    func isValid(value: Any) -> Bool {
        guard value is T else {
            return false
        }
        return self.validator(value as! T)
    }

    init(_ key: String, validator: @escaping FieldValidator<T>, customDefault: T?) {
        self.key = key
        self.validator = validator
        _customDefault = customDefault
    }

    init(_ key: String, validator: @escaping FieldValidator<T>) {
        self.key = key
        self.validator = validator
    }

    convenience init(_ key: String, customDefault: T? = nil) {
        self.init(key, validator: alwaysValid, customDefault: customDefault)
    }

    func copyReferencing(_ representation: Representation) -> Field {
        fatalError("FieldBase.copyReferencing cannot be directly invoked. Use a subclass.")
    }

    func update(to value: T, via source: SourceIdentifiable) throws {
        fatalError("FieldBase.update cannot be directly invoked. Use a subclass.")
    }

    func update(to value: T, silently: Bool = false) throws {
        fatalError("FieldBase.update cannot be directly invoked. Use a subclass.")
    }

    func clear(via source: SourceIdentifiable) throws {
        fatalError("FieldBase.clear cannot be directly invoked. Use a subclass.")
    }

    func clear(silently: Bool = false) throws {
        fatalError("FieldBase.clear cannot be directly invoked. Use a subclass.")
    }
}


class ImmutableField<T:FieldUsable>: FieldBase<T> {

    init(_ key: String) {
        super.init(key, validator: alwaysValid)
    }

    override func update(to value: T, via source: SourceIdentifiable) throws {
        throw SchemaError.fieldNotMutable(type: representationType, field: self.key)
    }

    override func update(to value: T, silently: Bool = false) throws {
        throw SchemaError.fieldNotMutable(type: representationType, field: self.key)
    }

    override func clear(via source: SourceIdentifiable) throws {
        throw SchemaError.fieldNotMutable(type: representationType, field: self.key)
    }

    override func clear(silently: Bool = false) throws {
        throw SchemaError.fieldNotMutable(type: representationType, field: self.key)
    }

    override func copyReferencing(_ representation: Representation) -> Field {
        let field = ImmutableField<T>(self.key)
        field.representation = representation
        return field
    }
}


class MutableField<T:FieldUsable>: FieldBase<T> {

    override func update(to value: T, via source: SourceIdentifiable) throws {
        try representation!.update(field: self.key, toValue: value, via: source)
    }

    override func update(to value: T, silently: Bool = false) throws {
        try representation!.update(field: self.key, toValue: value, via: nil, silently: silently)
    }

    override func clear(via source: SourceIdentifiable) throws {
        representation!.remove(field: self.key, via: source)
    }

    override func clear(silently: Bool = false) throws {
        representation!.remove(field: self.key, via: nil, silently: silently)
    }

    override func copyReferencing(_ representation: Representation) -> Field {
        let field = MutableField<T>(self.key)
        field.representation = representation
        return field
    }
}


typealias Computation<T:FieldUsable> = (Representation) -> T

class ComputedField<T:FieldUsable>: ImmutableField<T> {
    internal let getter: Computation<T>

    override var value: T? {
        return getter(representation!)
    }

    init(_ key: String, getter: @escaping Computation<T> ) {
        self.getter = getter
        super.init(key)
    }
}


private class _AnyFieldBase<T:FieldUsable>: TypedField {
    var name: String { fatalError("Must override.") }
    var stringValue: String { fatalError("Must override.") }
    var value: T? { fatalError("Must override.") }
    var rawValue: T? { fatalError("Must override") }
    var representationType: String { get { fatalError("Must override.") } }

    init() {
        guard type(of: self) != _AnyFieldBase.self else {
            fatalError("_AnyFieldBase<T> instances can not be created; create a subclass instance instead")
        }
    }


    func isValid(value: Any) -> Bool { fatalError("Use subclass") }
    func copyReferencing(_ representation: Representation) -> Field { fatalError("Use subclass") }
    func update(to value: T, via source: SourceIdentifiable) throws { fatalError("Use subclass") }

    func update(to value: T, silently: Bool = false) throws {
        fatalError("Cannot be directly invoked. Use a subclass.")
    }

    func clear(via source: SourceIdentifiable) throws {
        fatalError("Cannot be directly invoked. Use a subclass.")
    }

    func clear(silently: Bool = false) throws {
        fatalError("Cannot be directly invoked. Use a subclass.")
    }
}


private final class _AnyFieldBox<Concrete: TypedField>: _AnyFieldBase<Concrete.Value> {
    // variable used since we're calling mutating functions
    var concrete: Concrete

    override var value: Concrete.Value? { return concrete.value }
    override var rawValue: Concrete.Value? { return concrete.rawValue }
    override var representationType: String { return concrete.representationType }

    init(_ concrete: Concrete) {
        self.concrete = concrete
    }

    override func isValid(value: Any) -> Bool {
        return self.concrete.isValid(value: value)
    }

    override func copyReferencing(_ representation: Representation) -> Field {
        return self.concrete.copyReferencing(representation)
    }

    override func update(to value: Concrete.Value, via source: SourceIdentifiable) throws {
        try self.concrete.update(to: value, via: source)
    }

    override func update(to value: Concrete.Value, silently: Bool = false) throws {
        try self.concrete.update(to: value, silently: silently)
    }

    override func clear(via source: SourceIdentifiable) throws {
        try self.concrete.clear(via: source)
    }

    override func clear(silently: Bool = false) throws {
        try self.concrete.clear(silently: silently)
    }
}


final class AnyField<T:FieldUsable>: TypedField {

    private let box: _AnyFieldBase<T>


    var name: String { return box.name }
    var stringValue: String { return box.stringValue }
    var value: T? { return box.value }
    var rawValue: T? { return box.rawValue }
    var representationType: String { return box.representationType }

    // Initializer takes our concrete implementer of Row i.e. FileCell
    init<Concrete: TypedField>(_ concrete: Concrete) where Concrete.Value == T {
        box = _AnyFieldBox(concrete)
    }

    func isValid(value: Any) -> Bool {
        return self.box.isValid(value: value)
    }

    func copyReferencing(_ representation: Representation) -> Field {
        return self.box.copyReferencing(representation)
    }

    func update(to value: T, via source: SourceIdentifiable) throws {
        try self.box.update(to: value, via: source)
    }

    func update(to value: T, silently: Bool = false) throws {
        try self.box.update(to: value, silently: silently)
    }

    func clear(via source: SourceIdentifiable) throws {
        try self.box.clear(via: source)
    }

    func clear(silently: Bool = false) throws {
        try self.box.clear(silently: silently)
    }
}
