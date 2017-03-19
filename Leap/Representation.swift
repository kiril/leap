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
    var store: RepresentationBackingStore?
    let type: String
    let id: String
    var data: [String:Any]
    var dirtyFields: Set<String> = Set<String>()

    let isTransient: Bool = false // possible that we change this later
    var isDirty: Bool = false
    var isPersisted: Bool = false
    var lastModified: NSDate?
    var lastPersisted: NSDate?

    internal var observers = [String:WeakObserver]()

    init(type: String, id: String, data: [String:Any]) {
        self.type = type
        self.id = id
        self.data = data
    }

    init(store: RepresentationBackingStore, type: String, id: String, data: [String:Any]) {
        self.store = store
        self.type = type
        self.id = id
        self.data = data
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
    func update(data: [String:Any], from source: SourceIdentifiable) {
        if !(source is RepresentationBackingStore) {
            isDirty = true
            if !isTransient {
                isPersisted = false
            }
            for (field, _) in data {
                dirtyFields.update(with: field)
            }
        }

        self.data = data

        self.purgeObservers()
        for (observerSourceId, ref) in self.observers {
            if let observer = ref.observer {
                guard observerSourceId != source.sourceId else { continue } // don't loop change notifications
                observer.representationDidChange(self)
            }
        }
    }

    func update(field: String, toValue: Any, from source: SourceIdentifiable) {
        if !(source is RepresentationBackingStore) {
            isDirty = true
            if !isTransient {
                isPersisted = false
            }
            dirtyFields.update(with: field)
        }

        self.purgeObservers()
        for (observerSourceId, ref) in self.observers {
            if let observer = ref.observer {
                guard observerSourceId != source.sourceId else { continue } // don't loop change notifications
                observer.representationDidChange(self)
            }
        }
    }
}

/**
 * Persistable implementation: the parts of Representation that allow it to interact with
 * a backing store, and represent its state vis a vis persistence.
 * Also see the variables defined on the class above, which are required parts of the protocol.
 */
extension Representation: Persistable {

    var isPersistable: Bool {
        return true
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
