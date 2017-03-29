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

    var isPersisted: Bool { get }
    var isPersistable: Bool { get }
    var lastPersisted: NSDate? { get }
    var lastModified: NSDate? { get }
    var nonPersistableKeys: [String] { get }

    func didPersist(into store: BackingStore)

    func flush() throws -> Bool
}


protocol Retrievable {
    associatedtype ConcreteSurface

    static func find(byId id: String) throws -> ConcreteSurface
}


protocol Queryable {
}

protocol Query {
    associatedtype ConcreteSurface

    func all() throws -> [ConcreteSurface]
    func first(_: Int) throws -> [ConcreteSurface]
    func any() throws -> ConcreteSurface
    func one() throws -> ConcreteSurface
}


/*
 * A Surface is in charge of communicating with its backing store,
 * which houses the underlying model(s) that the Surface is standing
 * in for.
 */
protocol BackingStore: SourceIdentifiable {
    func persist(_ surface : Surface) throws -> Bool
    func populate(_ surface: Surface)
}
