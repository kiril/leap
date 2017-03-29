//
//  Bridge.swift
//  Leap
//
//  Created by Kiril Savino on 3/28/17.
//  Copyright © 2017 Single Leap, Inc. All rights reserved.
//

import Foundation
import RealmSwift

typealias FieldMapping = [String:String]

typealias FieldReader = () -> Any?
typealias FieldWriter = (Any?) throws -> Bool

class Bridge: BackingStore {
    var sourceId: String
    var readers: [String:FieldReader] = [:]
    var writers: [String:FieldWriter] = [:]

    init(id: String) {
        sourceId = id

    }

    func configure() {
        fatalError("Should be overridden")
    }

    func read(_ field: Property, with reader: @escaping FieldReader) {
        readers[field.key] = reader
    }

    func write(_ field: Property, with writer: @escaping FieldWriter) {
        writers[field.key] = writer
    }

    func populate(_ surface: Surface) {
        for key in surface.keys {
            if let reader = readers[key],
                let value = reader() {
                try! surface.update(key: key, toValue: value, via: self)
            }
        }
    }

    func persist(_ surface: Surface) throws -> Bool {
        return false

        /*
        var changed = false

        for operation in surface.operations {
            var modelData: ModelData = [:]
            if operation.apply(&modelData) {
                changed = true
            }
        }

        return changed
 */
    }
}
