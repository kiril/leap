//
//  Operation.swift
//  Leap
//
//  Created by Kiril Savino on 3/28/17.
//  Copyright © 2017 Single Leap, Inc. All rights reserved.
//

import Foundation


enum OperationType: String {
    case set       = "set"
    case unset     = "unset"
    case increment = "inc"
    case decrement = "dec"
    case push      = "push"
    case pull      = "pull"
}

protocol Operation {
    var type: OperationType { get }
    var field: String { get }
    var value: Any? { get }
    func apply(_ data: inout ModelData) -> Bool
}

class SetOperation: Operation {
    let type: OperationType = OperationType.set
    var field: String
    var value: Any?

    init(_ field: String, to value: Any) {
        self.field = field
        self.value = value
    }

    func apply(_ data: inout ModelData) -> Bool {
        if data[field] ~= value {
            return false // samesies!
        }
        data[field] = value
        return true
    }
}

class UnsetOperation: Operation {
    let type: OperationType = OperationType.unset
    let value: Any? = nil
    var field: String

    init(_ field: String) {
        self.field = field
    }

    func apply(_ data: inout ModelData) -> Bool {
        if data[field] == nil {
            return false
        }
        data.removeValue(forKey: field)
        return true
    }
}

infix operator ~=

func ~= (left: Any?, right: Any?) -> Bool {
    guard (left == nil) == (right == nil) else {
        return false
    }
    if left == nil {
        return true
    }
    if let left = left, let right = right {
        guard type(of: left) == type(of: right) else {
            return false
        }
        switch left {
        case let s as String:
            return s == (right as! String)
        case let i as Int:
            return i == (right as! Int)
        case let f as Float:
            return f == (right as! Float)
        case let d as Double:
            return d == (right as! Double)
        case let b as Bool:
            return b == (right as! Bool)
        case let d as [String:String]:
            return d == (right as! [String:String])
        default:
            return false
        }
    }
    return false
}

infix operator !~=

func !~= (left: Any?, right: Any?) -> Bool {
    return !(left ~= right)
}

func coalesce(operations: [Operation]) {
}
