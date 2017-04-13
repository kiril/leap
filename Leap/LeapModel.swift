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

    func delete() {
        let realm = Realm.user()
        try! realm.safeWrite {
            realm.delete(self)
        }
    }

    func insert() {
        let realm = Realm.user()
        try! realm.safeWrite {
            realm.add(self)
        }
    }

    func update() {
        let realm = Realm.user()
        try! realm.safeWrite {
            realm.add(self, update: true)
        }
    }

    static func fetch<ModelType:Object>(id: String) -> ModelType? {
        return Realm.user().objects(ModelType.self).filter("id = %@", id).first
    }
}
