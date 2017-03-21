//
//  RepresentationValidation.swift
//  Leap
//
//  Created by Kiril Savino on 3/19/17.
//  Copyright © 2017 Single Leap, Inc. All rights reserved.
//

typealias FieldValidator<T> = (T) -> Bool


func alwaysValid<T>(value: T) -> Bool {
    return true
}


func validIfNot(string badString: String) -> FieldValidator<String> {
    return {(value:String) in
        return value != badString
    }
}


func validIfAtLeast(characters: Int) -> FieldValidator<String> {
    return {(value: String) in
        return value.characters.count >= characters
    }
}

func validIfGreaterThan(int: Int) -> FieldValidator<Int> {
    return {(value: Int) in
        return value > int
    }
}
