//
//  Representation.swift
//  Leap
//
//  Created by Kiril Savino on 3/18/17.
//  Copyright © 2017 Single Leap, Inc. All rights reserved.
//

import Foundation
import SwiftyJSON


/**
 * In order to tread RepresentationObserver objects as weak references,
 * and have multiple of them stored for a given Representation,
 * we have to only put weakly held references to them into our collection.
 */
internal class WeakObserver {
    weak var observer: RepresentationObserver?
    init(_ observer: RepresentationObserver) {
        self.observer = observer
    }
}


/**
 * This is the big show! A Representation is a ViewModel type that
 * allows a View/Controller (Interface) to deal with data that's backed by
 * a Model somewhere, without knowing about that Model, and both update the
 * underlying Model via the Representation, and receive updates about changes
 * to the data this Representation holds.
 */
open class Representation {
    let id: String?
    private let schema: Schema

    internal var fields: [String:Field] = [String:Field]()

    internal var store: RepresentationBackingStore?
    internal var data: [String:Any]
    internal var dirtyFields: Set<String> = []

    var type: String {
        return schema.type
    }


    let isTransient: Bool = false // possible that we change this later
    var isDirty: Bool = false
    var isPersisted: Bool = false
    var lastModified: NSDate?
    var lastPersisted: NSDate?

    internal var observers = [String:WeakObserver]()

    init(schema: Schema, id: String?, data: [String:Any]) {
        self.schema = schema
        self.id = id
        self.data = data
        self.fields = schema.fieldMap(for: self)
    }

    init(store: RepresentationBackingStore, schema: Schema, id: String?, data: [String:Any]) {
        self.store = store
        self.schema = schema
        self.id = id
        self.data = data
        self.fields = schema.fieldMap(for: self)
    }


    func mutable<Value>(_ name: String) -> MutableField<Value> {
        return self.fields[name] as! MutableField<Value>
    }

    func immutable<Value>(_ name: String) -> ImmutableField<Value> {
        return self.fields[name] as! ImmutableField<Value>
    }

    func setValue(_ value: Any, forKey key: String, via source: SourceIdentifiable) throws {
        try self.update(field: key, toValue: value, via: source)
    }

    func purgeObservers() {
        observers.forEach { if $1.observer == nil { observers[$0] = nil } }
    }

    func asJSON() -> JSON {
        return JSON(self.data)
    }
}

/**
 * Just to separate out the Observable conformance of the Representation.
 * I can't imagine that anything else would ever conform to Observable,
 * because it's specifically tied to this class cluster, but this at least
 * makes it clear how we're dividing up the semantics of this class.
 *
 * A fundamental thing about Representations is that you can observe changes to them.
 */
extension Representation: Observable {
    func register(observer: RepresentationObserver) {
        self.observers[observer.sourceId] = WeakObserver(observer)
    }

    func deregister(observer: RepresentationObserver) {
        self.observers.removeValue(forKey: observer.sourceId)
    }
}

/**
 * Again, separating out the Updateable conformance.
 * Representations can be updated by either a BackingStore, or by
 * some Interface component (Model or more likely Controller).
 * We'll propagate those changes to all Observers, but avoid
 * having an observer accidentally notify itself of changes its making,
 * resulting in update or render loops, by keeping track of where a
 * change originated, and not notifying the originating Source.
 */
extension Representation: Updateable {
    func update(data: [String:Any], via source: SourceIdentifiable?, silently: Bool = false) throws {
        for (key, value) in data {
            guard let fieldDef = fields[key] else {
                throw SchemaError.noSuchField(type: self.type, field: key)
            }
            guard fieldDef.isValid(value: value) else {
                throw SchemaError.invalidValueForField(type: self.type, field: key, value: value)
            }
        }

        self.data = data

        if !(source is RepresentationBackingStore) {
            isDirty = true
            if !isTransient {
                isPersisted = false
            }
            for (field, _) in data {
                dirtyFields.update(with: field)
            }
        }

        if !silently {
            self.purgeObservers()
            for (observerSourceId, ref) in self.observers {
                if let observer = ref.observer {
                    if let source = source {
                        guard observerSourceId != source.sourceId else { continue } // don't loop change notifications
                    }
                    observer.representationDidChange(self)
                }
            }
        }
    }

    func update(field: String, toValue value: Any, via source: SourceIdentifiable?, silently: Bool = false) throws {
        guard let fieldDef = fields[field] else {
            throw SchemaError.noSuchField(type: self.type, field: field)
        }
        guard fieldDef.isValid(value: value) else {
            throw SchemaError.invalidValueForField(type: self.type, field: field, value: value)
        }

        data[field] = value

        if !(source is RepresentationBackingStore) {
            isDirty = true
            if !isTransient {
                isPersisted = false
            }
            dirtyFields.update(with: field)
        }

        if !silently {
            self.purgeObservers()
            for (observerSourceId, ref) in self.observers {
                if let observer = ref.observer {
                    if let source = source {
                        guard observerSourceId != source.sourceId else { continue } // don't loop change notifications
                    }
                    observer.representationDidChange(self)
                }
            }
        }
    }

    func remove(field: String, via source: SourceIdentifiable?, silently: Bool = false) {
        data[field] = nil

        if !(source is RepresentationBackingStore) {
            isDirty = true
            if !isTransient {
                isPersisted = false
            }
            dirtyFields.update(with: field)
        }

        if !silently {
            self.purgeObservers()
            for(observerSourceId, ref) in self.observers {
                if let observer = ref.observer {
                    if let source = source {
                        guard observerSourceId != source.sourceId else { continue }
                    }
                    observer.representationDidChange(self)
                }
            }
        }
    }

    func update(data: [String:Any]) throws {
        try self.update(data: data, via: nil)
    }

    func update(field: String, toValue value: Any) throws {
        print("calling convenience update...")
        try self.update(field: field, toValue: value, via: nil)
    }

    func remove(field: String) {
        self.remove(field: field, via: nil)
    }
    
    func updateSilently(data: [String:Any]) throws {
        try self.update(data: data, via: nil, silently: true)
    }

    func updateSilently(field: String, toValue value: Any) throws {
        try self.update(field: field, toValue: value, via: nil, silently: true)
    }

    func removeSilently(field: String) {
        self.remove(field: field, via: nil, silently: true)
    }
}

/**
 * Persistable implementation: the parts of Representation that allow it to interact with
 * a backing store, and represent its state vis a vis persistence.
 * Also see the variables defined on the class above, which are required parts of the protocol.
 */
extension Representation: Persistable {

    var isPersistable: Bool {
        return self.id != nil // AND more stuff
    }


    var nonPersistableFields: [String] {
        return [String]()
    }

    func didPersist(into store: RepresentationBackingStore) {
        self.purgeObservers()
        for (_, ref) in self.observers {
            if let observer:RepresentationLifecycleObserver = ref.observer as? RepresentationLifecycleObserver {
                observer.representationDidPersist(self)
            }
        }
    }

    func persist() throws -> Bool {
        return try self.store?.persist(self) ?? false
    }
}
