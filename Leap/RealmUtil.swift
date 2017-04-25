//
//  RealmUtil.swift
//  Leap
//
//  Created by Kiril Savino on 3/28/17.
//  Copyright © 2017 Single Leap, Inc. All rights reserved.
//

import Foundation
import RealmSwift


typealias ModelData = [String:Any]


protocol ValueWrapper {
    associatedtype T
    var raw: T { get }
}

extension ValueWrapper {
    static func primaryKey() -> String? {
        return "raw"
    }
}



class IntWrapper: Object, ValueWrapper {
    dynamic var raw: Int = 0

    static func of(_ int: Int) -> IntWrapper {
        return IntWrapper(value: ["raw": int])
    }

    static func of(num: NSNumber) -> IntWrapper {
        return IntWrapper(value: ["raw": num.intValue])
    }

    override func isEqual(_ object: Any?) -> Bool {
        if let iw = object as? IntWrapper {
            return iw.raw == raw
        }
        return false
    }
}

class StringWrapper: Object, ValueWrapper {
    dynamic var raw: String = ""

    convenience init(_ string: String) {
        self.init(value: ["raw": string])
    }

    override func isEqual(_ object: Any?) -> Bool {
        if  let rhs = object as? StringWrapper {
            let lhs = self
            return lhs.raw == rhs.raw
        }
        return false
    }
}
