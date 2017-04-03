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

    @discardableResult
    func set(value: Any?, forKeysRecursively keys: [String]) -> Any? {
        guard let key = keys.first, let next = self[key] else {
            return nil
        }
        let rest = keys.dropLast()
        guard rest.count > 0 else {
            let oldValue = self[key]
            self[key] = value
            return oldValue
        }
        guard let object = next as? Object else {
            return nil
        }
        return object.set(value: value, forKeysRecursively: Array<String>(rest))
    }

    @discardableResult
    func set(value: Any?, forKeyPath path: String) -> Any? {
        return set(value: value, forKeysRecursively: path.components(separatedBy: "."))
    }
}
