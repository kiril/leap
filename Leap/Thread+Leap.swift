//
//  Thread+Leap.swift
//  Leap
//
//  Created by Kiril Savino on 4/19/17.
//  Copyright © 2017 Single Leap, Inc. All rights reserved.
//

import Foundation

extension Thread {
    static func getValue<T>(forKey key: String) -> T? {
        return current.threadDictionary[key] as? T
    }

    static func set(value: Any, forKey key: String) {
        current.threadDictionary[key] = value
    }
}
