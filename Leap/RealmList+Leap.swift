//
//  RealmList+Leap.swift
//  Leap
//
//  Created by Kiril Savino on 5/16/17.
//  Copyright © 2017 Single Leap, Inc. All rights reserved.
//

import Foundation
import RealmSwift

extension List where T: IntWrapper {
    func hasEqualContents(to other: List<IntWrapper>) -> Bool {
        guard self.count == other.count else { return false }
        for (i, e) in self.enumerated() {
            if e != other[i] {
                return false
            }
        }
        return true
    }
}
