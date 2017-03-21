//
//  RepresentationValidation.swift
//  Leap
//
//  Created by Kiril Savino on 3/19/17.
//  Copyright © 2017 Single Leap, Inc. All rights reserved.
//

typealias Validator<T> = (T) -> Bool


func alwaysValid<T>(value: T) -> Bool {
    return true
}


func validIfNot(string badString: String) -> Validator<String> {
    return {(value:String) in
        return value != badString
    }
}


func validIfAtLeast(characters: Int) -> Validator<String> {
    return {(value: String) in
        return value.characters.count >= characters
    }
}

func validIfGreaterThan(int: Int) -> Validator<Int> {
    return {(value: Int) in
        return value > int
    }
}
