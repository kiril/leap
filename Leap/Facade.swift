//
//  Facade.swift
//  Leap
//
//  Created by Kiril Savino on 3/28/17.
//  Copyright © 2017 Single Leap, Inc. All rights reserved.
//

import Foundation
import RealmSwift

typealias FieldMapping = [String:String]


class Facade: BackingStore {
    var sourceId: String
    var mapping: FieldMapping
    var references: [Reference]

    init(id: String, mapping: FieldMapping, references: [Reference]) {
        sourceId = id
        self.references = references
        self.mapping = mapping
    }

    func persist(_ shell: Shell) throws -> Bool {
        var changed = false

        for operation in shell.operations {
            var modelData: ModelData = [:]
            if operation.apply(&modelData) {
                changed = true
            }
        }

        return changed
    }
}
