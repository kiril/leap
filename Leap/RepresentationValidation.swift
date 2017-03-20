//
//  RepresentationValidation.swift
//  Leap
//
//  Created by Kiril Savino on 3/19/17.
//  Copyright © 2017 Single Leap, Inc. All rights reserved.
//

typealias FieldValidator = (Any) -> Bool


func alwaysValid(value: Any) -> Bool {
    return true
}


func validIfNot(string badString: String) -> FieldValidator {
    return {(value: Any) in
        guard let s = value as? String, s == badString else {
            return false
        }
        return true
    }
}


func validIfAtLeast(characters: Int) -> FieldValidator {
    return {(value: Any) in
        guard let s = value as? String, s.characters.count >= characters else {
            return false
        }
        return true
    }
}

func validIfGreaterThan(int: Int) -> FieldValidator {
    return {(value: Any) in
        guard let i = value as? Int, i > int else {
            return false
        }
        return true
    }
}
