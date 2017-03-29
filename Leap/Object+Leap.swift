//
//  Object+Leap.swift
//  Leap
//
//  Created by Kiril Savino on 3/29/17.
//  Copyright © 2017 Single Leap, Inc. All rights reserved.
//

import Foundation
import RealmSwift

extension Object {
    func getValue(forKeysRecursively keys: [String]) -> Any? {
        guard let key = keys.first, let next = self[key] else {
            return nil
        }
        let rest = keys.dropLast()
        guard rest.count > 0 else {
            return next
        }
        guard let object = next as? Object else {
            return nil
        }
        return object.getValue(forKeysRecursively: Array<String>(rest))
    }

    func getValue(forKeyPath path: String) -> Any? {
        return getValue(forKeysRecursively: path.components(separatedBy: "."))
    }
}
