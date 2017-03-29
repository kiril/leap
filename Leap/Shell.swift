//
//  Shell.swift
//  Leap
//
//  Created by Kiril Savino on 3/18/17.
//  Copyright © 2017 Single Leap, Inc. All rights reserved.
//

import Foundation
import SwiftyJSON


/**
 * In order to tread ShellObserver objects as weak references,
 * and have multiple of them stored for a given Shell,
 * we have to only put weakly held references to them into our collection.
 */
internal class WeakObserver {
    weak var observer: ShellObserver?
    init(_ observer: ShellObserver) {
        self.observer = observer
    }
}


/**
 * This is the big show! A Shell is a ViewModel type that
 * allows a View/Controller (Interface) to deal with data that's backed by
 * a Model somewhere, without knowing about that Model, and both update the
 * underlying Model via the Shell, and receive updates about changes
 * to the data this Shell holds.
 */
open class Shell {
    let id: String?

    internal var properties: [String:Property] = [String:Property]()

    internal var store: BackingStore?
    internal var data: ModelData
    internal var mockData: ModelData?
    internal var operations = [Operation]()

    var dirtyFields: Set<String> {
        var set = Set<String>()
        for operation in operations {
            set.insert(operation.field)
        }
        return set
    }

    var type: String {
        return "shell" // default to class name?
    }

    var keys: Set<String> {
        return Set<String>(properties.keys)
    }

    let isTransient: Bool = false // possible that we change this later
    var isDirty: Bool = false
    var isPersisted: Bool = false
    var lastModified: NSDate?
    var lastPersisted: NSDate?

    internal var observers = [String:WeakObserver]()

    init(store: BackingStore? = nil,
         id: String? = nil,
         data: [String:Any] = [:]) {

        self.store = store
        self.id = id
        self.data = data

        associateProperties()
    }

    convenience init(mockData data: ModelData) {
        self.init(store: nil, id: nil, data: data)
        self.mockData = data
    }

    private func associateProperties() {
        let me = Mirror(reflecting: self)
        for child in me.children {
            if var property = child.value as? Property {
                property.shell = self
                properties[child.label!] = property
            }
        }
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
}

/**
 * Just to separate out the Observable conformance of the Shell.
 * I can't imagine that anything else would ever conform to Observable,
 * because it's specifically tied to this class cluster, but this at least
 * makes it clear how we're dividing up the semantics of this class.
 *
 * A fundamental thing about Shell is that you can observe changes to them.
 */
extension Shell: Observable {
    func register(observer: ShellObserver) {
        self.observers[observer.sourceId] = WeakObserver(observer)
    }

    func deregister(observer: ShellObserver) {
        self.observers.removeValue(forKey: observer.sourceId)
    }
}

/**
 * Again, separating out the Updateable conformance.
 * Shells can be updated by either a BackingStore, or by
 * some Interface component (Model or more likely Controller).
 * We'll propagate those changes to all Observers, but avoid
 * having an observer accidentally notify itself of changes its making,
 * resulting in update or render loops, by keeping track of where a
 * change originated, and not notifying the originating Source.
 */
extension Shell: Updateable {
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
            isDirty = true
            if !isTransient {
                isPersisted = false
            }
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
                    observer.shellDidChange(self)
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
            isDirty = true
            if !isTransient {
                isPersisted = false
            }

            operations.append(SetOperation(key, to: value, from: data[key]))
        }

        data[key] = value

        if !silently {
            self.purgeObservers()
            for (observerSourceId, ref) in self.observers {
                if let observer = ref.observer {
                    if let source = source {
                        guard observerSourceId != source.sourceId else { continue } // don't loop change notifications
                    }
                    observer.shellDidChange(self)
                }
            }
        }
    }

    func remove(key: String, via source: SourceIdentifiable?, silently: Bool = false) {

        if !(source is BackingStore) {
            isDirty = true
            if !isTransient {
                isPersisted = false
            }
            operations.append(UnsetOperation(key, from: data[key]))
        }

        data[key] = nil

        if !silently {
            self.purgeObservers()
            for(observerSourceId, ref) in self.observers {
                if let observer = ref.observer {
                    if let source = source {
                        guard observerSourceId != source.sourceId else { continue }
                    }
                    observer.shellDidChange(self)
                }
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
}

/**
 * Persistable implementation: the parts of Shell that allow it to interact with
 * a backing store, and represent its state vis a vis persistence.
 * Also see the variables defined on the class above, which are required parts of the protocol.
 */
extension Shell: Persistable {

    var isPersistable: Bool {
        return self.id != nil // AND more stuff
    }

    var nonPersistableKeys: [String] {
        return [String]()
    }

    func didPersist(into store: BackingStore) {
        self.purgeObservers()
        for (_, ref) in self.observers {
            if let observer:LifecycleObserver = ref.observer as? LifecycleObserver {
                observer.shellDidPersist(self)
            }
        }
    }

    func flush() throws -> Bool {
        return try self.store?.persist(self) ?? false
    }
}
