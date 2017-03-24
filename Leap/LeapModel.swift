//
//  LeapModel.swift
//  Leap
//
//  Created by Kiril Savino on 3/22/17.
//  Copyright © 2017 Single Leap, Inc. All rights reserved.
//

import Foundation
import RealmSwift

class LeapModel: Object, Auditable {
    dynamic var id: String = UUID().uuidString
    dynamic var created: Date?
    dynamic var updated: Date?
    dynamic var deleted: Date?
    dynamic var statusString: String = ObjectStatus.active.rawValue

    override static func primaryKey() -> String? {
        return "id"
    }

    var status: ObjectStatus {
        get { return ObjectStatus(rawValue: statusString)! }
        set { statusString = newValue.rawValue }
    }
}
