//
//  FuzzyHashable.swift
//  Leap
//
//  Created by Kiril Savino on 4/26/17.
//  Copyright © 2017 Single Leap, Inc. All rights reserved.
//

import Foundation
import RealmSwift

protocol Fuzzy {
    func calculateFuzzyHash() -> Int
}

protocol FuzzyHashable {
    var fuzzyHash: Int { get set }

    func storeFuzzyHash()
    func fuzzyEqual(_ object: LeapModel) -> Bool

    static func by(fuzzyHash: Int) -> LeapModel?
}

extension FuzzyHashable where Self:LeapModel {
    static func by(fuzzyHash: Int) -> Self? {
        return fuzzyHash == 0 ? nil : Self.by("fuzzyHash", is: fuzzyHash)
    }

    func fuzzyEqual(_ object: LeapModel) -> Bool {
        if let fuzzy = object as? Self {
            return fuzzy.fuzzyHash == fuzzyHash
        }
        return false
    }
}

extension LeapModel: FuzzyHashable {
    func storeFuzzyHash() {
        if let fuzzy = self as? Fuzzy {
            fuzzyHash = fuzzy.calculateFuzzyHash()
        } else {
            fuzzyHash = id.hashValue
        }
    }
}
