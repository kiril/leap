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
 * Shell conforms to the Observable protocol, which
 * allows Observers to register themselves for updates about
 * the Shell's state.
 */
protocol Observable {
    func register(observer: ShellObserver)
    func deregister(observer: ShellObserver)
}


/*
 * ReprsentationObservers are the most basic kind of observer that
 * can get notifications about changes to a Shell.
 *
 * All they get is an update when anything about the Shell's
 * underlying data changes.
 */
protocol ShellObserver: AnyObject, SourceIdentifiable {
    func shellDidChange(_ shell: Shell)
}


/**
 * A more advanced form of ShellObserver, LifecycleObservers
 * also get updates about what happens to the storage state of the underlying
 * Shell.
 */
protocol LifecycleObserver: ShellObserver {
    func shellDidPersist(_ shell: Shell)
    func shellWasDeleted(_ shell: Shell)
}
