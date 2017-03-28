//
//  RealmUtil.swift
//  Leap
//
//  Created by Kiril Savino on 3/28/17.
//  Copyright © 2017 Single Leap, Inc. All rights reserved.
//

import Foundation
import RealmSwift


protocol ValueWrapper {
    associatedtype T
    var value: T { get }
}

extension ValueWrapper {
    static func primaryKey() -> String? {
        return "value"
    }
}



class IntWrapper: Object, ValueWrapper {
    var value: Int = 0

    static func of(_ int: Int) -> IntWrapper {
        return IntWrapper(value: ["value": int])
    }

    static func of(num: NSNumber) -> IntWrapper {
        return IntWrapper(value: ["value": num.intValue])
    }
}
