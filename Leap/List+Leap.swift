//
//  List+Leap.swift
//  Leap
//
//  Created by Kiril Savino on 4/13/17.
//  Copyright © 2017 Single Leap, Inc. All rights reserved.
//

import Foundation
import RealmSwift

extension List {
    func containsEqualTo<T:Equatable>(_ object: T) -> Bool {
        print("----- containsEqualTo")
        for o in self {
            if let t = o as? T {
                print("Ok, got one...")
                if t == object {
                    print("Well, actually found some equal")
                    return true
                }
            }
            print("\(o) != \(object)")
        }
        return false
    }
}
