//
//  Schema.swift
//  Leap
//
//  Created by Kiril Savino on 3/19/17.
//  Copyright © 2017 Single Leap, Inc. All rights reserved.
//


public enum SchemaError: Error {
    case notWritable(type: String, property: String)
    case invalidValueFor(type: String, property: String, value: Any)
    case noSuch(type: String, property: String)
}
