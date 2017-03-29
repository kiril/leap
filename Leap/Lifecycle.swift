//
//  Lifecycle.swift
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
    func update(key: String, toValue value: Any, via source: SourceIdentifiable?, silently: Bool) throws
    func remove(key: String, via source: SourceIdentifiable?, silently: Bool)
    func update(data: [String:Any]) throws
    func update(key: String, toValue value: Any) throws
    func remove(key: String)
    func updateSilently(data: [String:Any]) throws
    func updateSilently(key: String, toValue value: Any) throws
    func removeSilently(key: String)
}


/*
 * Surface conforms to the Observable protocol, which
 * allows Observers to register themselves for updates about
 * the Surface's state.
 */
protocol Observable {
    func register(observer: SurfaceObserver)
    func deregister(observer: SurfaceObserver)
}


/*
 * ReprsentationObservers are the most basic kind of observer that
 * can get notifications about changes to a Surface.
 *
 * All they get is an update when anything about the Surface's
 * underlying data changes.
 */
protocol SurfaceObserver: AnyObject, SourceIdentifiable {
    func surfaceDidChange(_ surface: Surface)
}


/**
 * A more advanced form of SurfaceObserver, LifecycleObservers
 * also get updates about what happens to the storage state of the underlying
 * Surface.
 */
protocol LifecycleObserver: SurfaceObserver {
    func surfaceDidPersist(_ surface: Surface)
    func surfaceWasDeleted(_ surface: Surface)
}
