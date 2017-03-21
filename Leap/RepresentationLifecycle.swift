//
//  RepresentationLifecycle.swift
//  Leap
//
//  Created by Kiril Savino on 3/19/17.
//  Copyright © 2017 Single Leap, Inc. All rights reserved.
//

/**
 * Something that we can identify with a String id.
 */
protocol SourceIdentifiable {
    var sourceId: String { get }
}


/**
 * Something that can have its data updated.
 */
protocol Updateable {
    func update(data: [String:Any], via source: SourceIdentifiable?, silently: Bool) throws
    func update(field: String, toValue value: Any, via source: SourceIdentifiable?, silently: Bool) throws
    func remove(field: String, via source: SourceIdentifiable?, silently: Bool)
    func update(data: [String:Any]) throws
    func update(field: String, toValue value: Any) throws
    func remove(field: String)
    func updateSilently(data: [String:Any]) throws
    func updateSilently(field: String, toValue value: Any) throws
    func removeSilently(field: String)
}


/*
 * Representation conforms to the Observable protocol, which
 * allows Observers to register themselves for updates about
 * the Representation's state.
 */
protocol Observable {
    func register(observer: RepresentationObserver)
    func deregister(observer: RepresentationObserver)
}


/*
 * ReprsentationObservers are the most basic kind of observer that
 * can get notifications about changes to a Representation.
 *
 * All they get is an update when anything about the Representation's
 * underlying data changes.
 */
protocol RepresentationObserver: AnyObject, SourceIdentifiable {
    func representationDidChange(_ representation: Representation)
}


/**
 * A more advanced form of RepresentationObserver, RepresentationLifecycleObservers
 * also get updates about what happens to the storage state of the underlying
 * Representation.
 */
protocol RepresentationLifecycleObserver: RepresentationObserver {
    func representationDidPersist(_ representation: Representation)
    func representationWasDeleted(_ representation: Representation)
}
