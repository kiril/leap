//
//  RepresentationBacking.swift
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

    var isPersisted: Bool { get }
    var isPersistable: Bool { get }
    var lastPersisted: NSDate? { get }
    var lastModified: NSDate? { get }
    var nonPersistableKeys: [String] { get }

    func didPersist(into store: RepresentationBackingStore)

    func persist() throws -> Bool
}


protocol Retrievable {
    associatedtype ConcreteRepresentation

    static func find(byId id: String) throws -> ConcreteRepresentation
}


protocol Queryable {
}

protocol Query {
    associatedtype ConcreteRepresentation

    func all() throws -> [ConcreteRepresentation]
    func first(_: Int) throws -> [ConcreteRepresentation]
    func any() throws -> ConcreteRepresentation
    func one() throws -> ConcreteRepresentation
}


/*
 * A representation is in charge of communicating with its backing store,
 * which houses the underlying model(s) that the Representation is standing
 * in for.
 */
protocol RepresentationBackingStore: SourceIdentifiable {
    func persist(_ representation: Representation) throws -> Bool
}
