//
//  List+Leap.swift
//  Leap
//
//  Created by Kiril Savino on 4/13/17.
//  Copyright © 2017 Single Leap, Inc. All rights reserved.
//

import Foundation
import RealmSwift

extension List where T == IntWrapper {
    func contains(_ int: Int) -> Bool {
        for wrapper in self {
            if wrapper.raw == int {
                return true
            }
        }
        return false
    }

    func append(_ int: Int) {
        self.append(IntWrapper.of(int))
    }
}
