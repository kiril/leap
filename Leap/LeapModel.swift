//
//  LeapModel.swift
//  Leap
//
//  Created by Kiril Savino on 3/22/17.
//  Copyright © 2017 Single Leap, Inc. All rights reserved.
//

import Foundation
import RealmSwift

class LeapModel: Object {
    dynamic var id: String = UUID().uuidString

    override static func primaryKey() -> String? {
        return "id"
    }
}
