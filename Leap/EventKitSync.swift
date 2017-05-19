//
//  EventKitSync.swift
//  Leap
//
//  Created by Kiril Savino on 5/19/17.
//  Copyright © 2017 Single Leap, Inc. All rights reserved.
//

import Foundation
import RealmSwift

class EventKitSync: Object {
    dynamic var date: Date?

    static func last() -> EventKitSync? {
        return Realm.user().objects(EventKitSync.self).sorted(byKeyPath: "date", ascending: false).first
    }

    static func lastSynced() -> Date? {
        return last()?.date
    }

    static func mark() {
        let realm = Realm.user()
        let sync = EventKitSync(value: ["date": Date()])
        try! realm.safeWrite {
            realm.add(sync)
        }
    }

    override static func indexedProperties() -> [String] {
        return ["date"]
    }
}
