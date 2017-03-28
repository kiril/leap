//
//  Persistence.swift
//  Leap
//
//  Created by Kiril Savino on 3/19/17.
//  Copyright © 2017 Single Leap, Inc. All rights reserved.
//

import Foundation

/**
 * A protocol defining an object that can be persisted to a backing store,
 * and the state that it should expose and manage.
 */
protocol Persistable {
    var type: String { get }
    var id: String? { get }

    var isTransient: Bool { get }
    var isDirty: Bool { get }
    var dirtyFields: Set<String> { get }
    var operations: [Operation] { get }

    var isPersisted: Bool { get }
    var isPersistable: Bool { get }
    var lastPersisted: NSDate? { get }
    var lastModified: NSDate? { get }
    var nonPersistableKeys: [String] { get }

    func didPersist(into store: BackingStore)

    func persist(_ shell: Shell) throws -> Bool
}


protocol Retrievable {
    associatedtype ConcreteShell

    static func find(byId id: String) throws -> ConcreteShell
}


protocol Queryable {
}

protocol Query {
    associatedtype ConcreteShell

    func all() throws -> [ConcreteShell]
    func first(_: Int) throws -> [ConcreteShell]
    func any() throws -> ConcreteShell
    func one() throws -> ConcreteShell
}


/*
 * A Shell is in charge of communicating with its backing store,
 * which houses the underlying model(s) that the Shell is standing
 * in for.
 */
protocol BackingStore: SourceIdentifiable {
    func persist(_ shell: Shell) throws -> Bool
}
