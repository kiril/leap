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
    var time: TimeInterval { get }
    var type: OperationType { get }
    var field: String { get }
    var value: Any? { get }
    func apply(_ data: inout ModelData) -> Bool
    func isNoOp() -> Bool
    func combine(with op: Operation) -> Operation?
}

class _Operation {
    let time = Date().timeIntervalSinceReferenceDate
}

class SetOperation: _Operation, Operation {
    let type: OperationType = OperationType.set
    var field: String
    var value: Any?
    var before: Any?

    init(_ field: String, to value: Any, from before: Any?) {
        self.field = field
        self.value = value
        self.before = before
    }

    func apply(_ data: inout ModelData) -> Bool {
        if data[field] ~= value {
            return false // samesies!
        }
        data[field] = value
        return true
    }

    func isNoOp() -> Bool {
        return before ~= value
    }

    func combine(with op: Operation) -> Operation? {
        guard self.field == op.field else {
            return nil
        }

        switch op {
        case is SetOperation, is UnsetOperation:
            return op.time > time ? op : self
        default:
            return nil
        }
    }
}

class UnsetOperation: _Operation, Operation {
    let type: OperationType = OperationType.unset
    let value: Any? = nil
    let before: Any?
    var field: String

    init(_ field: String, from before: Any?) {
        self.field = field
        self.before = before
    }

    func apply(_ data: inout ModelData) -> Bool {
        if data[field] == nil {
            return false
        }
        data.removeValue(forKey: field)
        return true
    }

    func isNoOp() -> Bool {
        return before == nil
    }

    func combine(with op: Operation) -> Operation? {
        guard self.field == op.field else {
            return nil
        }

        switch op {
        case is SetOperation, is UnsetOperation:
            return op.time > time ? op : self
        default:
            return nil
        }
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

/*
func coalesce(operations: [Operation]) -> [Operation] {
    var results = [Operation]()
    for op in operations {
        if op.isNoOp() {
            continue
        }
        var toRemove = [Operation]()
        for op2 in results {
            if let combined = op.combine(with: op2) {
                toRemove.append(op2)
            }
        }
        results.append(op)
    }
    return results
}
*/
