//
//  Surface.swift
//  Leap
//
//  Created by Kiril Savino on 3/18/17.
//  Copyright © 2017 Single Leap, Inc. All rights reserved.
//

import Foundation
import SwiftyJSON



protocol KeyConvertible {
}

extension String: KeyConvertible {
}

extension Int: KeyConvertible {
}


/**
 * In order to tread SurfaceObserver objects as weak references,
 * and have multiple of them stored for a given Surface,
 * we have to only put weakly held references to them into our collection.
 */
internal class WeakObserver {
    weak var observer: SurfaceObserver?
    init(_ observer: SurfaceObserver) {
        self.observer = observer
    }
}


/**
 * This is the big show! A Surface is a ViewModel type that
 * allows a View/Controller (Interface) to deal with data that's backed by
 * a Model somewhere, without knowing about that Model, and both update the
 * underlying Model via the Surface, and receive updates about changes
 * to the data this Surface holds.
 */
open class Surface {
    let id: String?

    var type: String { fatalError("Must override type") }

    public fileprivate (set) var keys: Set<String> = []
    fileprivate var properties: [String:Property] = [:]

    var store: BackingStore?
    fileprivate var mockData: ModelData?
    fileprivate var data: ModelData

    fileprivate var operations: [Operation] = []

    var isTransient: Bool { return store == nil }

    var dirtyFields: Set<String> {
        var set = Set<String>()
        for operation in operations {
            set.insert(operation.field)
        }
        return set
    }

    var isDirty: Bool {
        return operations.count > 0
    }

    var isPersisted: Bool {
        return !isTransient && !isDirty
    }


    var lastModified: NSDate?
    var lastPersisted: NSDate?

    internal var observers = [String:WeakObserver]()

    init(store: BackingStore? = nil, id: String? = nil, data: ModelData = [:]) {
        self.store = store
        self.id = id
        self.data = data

        associateProperties()
    }

    convenience init(mockData data: ModelData, id: String? = nil) {
        self.init(store: nil, id: id, data: data)
        self.mockData = data
    }

    private func associateProperties() {
        let me = Mirror(reflecting: self)
        for child in me.children {
            if var property = child.value as? Property {
                property.surface = self
                if !property.hasKey {
                    property.setKey(child.label!)
                }
                self.keys.update(with: property.key)
                properties[property.key] = property
            }
        }
    }

    private func property(named name: String) -> Property? {
        return properties[name]
    }

    func getValue(for key: String) -> Any? {
        return data[key]
    }

    func mockValue<T>(for key: String) -> T? {
        return mockData?[key] as? T
    }

    func setValue(_ value: Any, forKey key: String, via source: SourceIdentifiable) throws {
        try self.update(key: key, toValue: value, via: source)
    }

    func purgeObservers() {
        observers.forEach { if $1.observer == nil { observers[$0] = nil } }
    }

    func asJSON() -> JSON {
        return JSON(self.data)
    }

    func populate() {
        store!.populate(self)
    }
}

/**
 * Just to separate out the Observable conformance of the Surface.
 * I can't imagine that anything else would ever conform to Observable,
 * because it's specifically tied to this class cluster, but this at least
 * makes it clear how we're dividing up the semantics of this class.
 *
 * A fundamental thing about Surface is that you can observe changes to them.
 */
extension Surface: Observable {
    func register(observer: SurfaceObserver) {
        self.observers[observer.sourceId] = WeakObserver(observer)
    }

    func deregister(observer: SurfaceObserver) {
        self.observers.removeValue(forKey: observer.sourceId)
    }
}

/**
 * Again, separating out the Updateable conformance.
 * Surfaces can be updated by either a BackingStore, or by
 * some Interface component (Model or more likely Controller).
 * We'll propagate those changes to all Observers, but avoid
 * having an observer accidentally notify itself of changes its making,
 * resulting in update or render loops, by keeping track of where a
 * change originated, and not notifying the originating Source.
 */
extension Surface: Updateable {
    func update(data: [String:Any], via source: SourceIdentifiable?, silently: Bool = false) throws {
        for (key, value) in data {
            guard let property = properties[key] else {
                throw SchemaError.noSuch(type: self.type, property: key)
            }
            guard property is Writable else {
                throw SchemaError.notWritable(type: self.type, property: key)
            }
            guard property.isValid(value: value) else {
                throw SchemaError.invalidValueFor(type: self.type, property: key, value: value)
            }
        }

        if !(source is BackingStore) {
            for (key, value) in data {
                if value !~= data[key] {
                    operations.append(SetOperation(key, to: value, from: data[key]))
                }
            }
        }

        self.data = data

        if !silently {
            self.purgeObservers()
            for (observerSourceId, ref) in self.observers {
                if let observer = ref.observer {
                    if let source = source {
                        guard observerSourceId != source.sourceId else { continue } // don't loop change notifications
                    }
                    observer.surfaceDidChange(self)
                }
            }
        }
    }

    func update(key: String, toValue value: Any, via source: SourceIdentifiable?, silently: Bool = false) throws {
        guard let property = properties[key] else {
            throw SchemaError.noSuch(type: self.type, property: key)
        }
        guard property is Writable || source is BackingStore else {
            print("\(key) is not writable on \(self.type) : \(property)")
            throw SchemaError.notWritable(type: self.type, property: key)
        }
        guard property.isValid(value: value) else {
            throw SchemaError.invalidValueFor(type: self.type, property: key, value: value)
        }

        if !(source is BackingStore) {
            operations.append(SetOperation(key, to: value, from: data[key]))
        }

        data[key] = value

        if !silently {
            self.notifyObserversOfChange(via: source)
        }
    }

    func remove(key: String, via source: SourceIdentifiable?, silently: Bool = false) {

        if !(source is BackingStore) {
            operations.append(UnsetOperation(key, from: data[key]))
        }

        data[key] = nil

        if !silently {
            self.notifyObserversOfChange(via: source)
        }
    }

    func notifyObserversOfChange(via source: SourceIdentifiable? = nil) {
        self.purgeObservers()
        for(observerSourceId, ref) in self.observers {
            if let observer = ref.observer {
                if let source = source {
                    guard observerSourceId != source.sourceId else { continue }
                }
                observer.surfaceDidChange(self)
            }
        }
    }

    func update(data: [String:Any]) throws {
        try self.update(data: data, via: nil)
    }

    func update(key: String, toValue value: Any) throws {
        try self.update(key: key, toValue: value, via: nil)
    }

    func remove(key: String) {
        self.remove(key: key, via: nil)
    }
    
    func updateSilently(data: [String:Any]) throws {
        try self.update(data: data, via: nil, silently: true)
    }

    func updateSilently(key: String, toValue value: Any) throws {
        try self.update(key: key, toValue: value, via: nil, silently: true)
    }

    func removeSilently(key: String) {
        self.remove(key: key, via: nil, silently: true)
    }

    // Convenience Classes for properties

    class SurfaceString: WritableProperty<String> {
        init(_ name: String? = nil, minLength: Int? = nil) {
            let validator = minLength == nil ? alwaysValid : validIfAtLeast(characters: minLength!)
            super.init(name, validatedBy: validator)
        }
    }

    class SurfaceDate: WritableProperty<Date> {
        init(_ name: String? = nil) {
            super.init(name)
        }
    }

    class SurfaceBool: WritableProperty<Bool> {
        init(_ name: String? = nil) {
            super.init(name)
        }
    }

    class SurfaceInt: WritableProperty<Int> {
        init(_ name: String? = nil) {
            super.init(name)
        }
    }

    class SurfaceFloat: WritableProperty<Float> {
        init(_ name: String? = nil) {
            super.init(name)
        }
    }

    class ComputedSurfaceString<SType:Surface>: ComputedProperty<String,SType> {
        init(_ name: String? = nil, by computation: @escaping Computation<String,SType>) {
            super.init(name, computation, referencing: nil)
        }
    }

    class ComputedSurfaceBool<SType:Surface>: ComputedProperty<Bool,SType> {
        init(_ name: String? = nil, by computation: @escaping Computation<Bool,SType>) {
            super.init(name, computation, referencing: nil)
        }
    }

    class ComputedSurfaceFloat<SType:Surface>: ComputedProperty<Float,SType> {
        init(_ name: String? = nil, by computation: @escaping Computation<Float,SType>) {
            super.init(name, computation, referencing: nil)
        }
    }

    class ComputedSurfaceInt<SType:Surface>: ComputedProperty<Int,SType> {
        init(_ name: String? = nil, by computation: @escaping Computation<Int,SType>) {
            super.init(name, computation, referencing: nil)
        }
    }

    class ComputedSurfaceProperty<ReturnType,SurfaceType:Surface>: ComputedProperty<ReturnType, SurfaceType> {
        init(_ name: String? = nil, by computation: @escaping Computation<ReturnType,SurfaceType>) {
            super.init(name, computation, referencing: nil)
        }
    }

    class SurfaceProperty<T>: WritableProperty<T> {
        init(_ name: String? = nil) {
            super.init(name)
        }
    }
}

/**
 * Persistable implementation: the parts of Surface that allow it to interact with
 * a backing store, and represent its state vis a vis persistence.
 * Also see the variables defined on the class above, which are required parts of the protocol.
 */
extension Surface: Persistable {

    var isPersistable: Bool {
        return self.store != nil // AND more stuff
    }

    var nonPersistableKeys: [String] {
        return []
    }

    func didPersist(into store: BackingStore) {
        self.purgeObservers()
        for (_, ref) in self.observers {
            if let observer:LifecycleObserver = ref.observer as? LifecycleObserver {
                observer.surfaceDidPersist(self)
            }
        }
    }

    @discardableResult
    func flush() throws -> Bool {
        return try self.store?.persist(self) ?? false
    }
}
