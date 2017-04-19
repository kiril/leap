//
//  Ignorance.swift
//  Leap
//
//  Created by Kiril Savino on 4/3/17.
//  Copyright © 2017 Single Leap, Inc. All rights reserved.
//

import Foundation
import RealmSwift

class Ignorance: LeapModel {
    dynamic var event: Event?
    dynamic var reminder: Reminder?

    static func of(_ thing: Temporality) -> Ignorance? {
        let realm = Realm.user()
        let query = realm.objects(Ignorance.self)
        switch thing {
        case let event as Event:
            return query.filter("event = %@", event).first
        case let reminder as Reminder:
            return query.filter("reminder = %@", reminder).first
        default:
            return nil
        }
    }

    @discardableResult
    static func ignore(_ thing: Temporality) -> Bool {
        if let _ = of(thing) {
            return false
        }
        let realm = Realm.user()
        var wrote: Bool = false

        try! realm.safeWrite {
            switch thing {
            case let event as Event:
                realm.add(Ignorance(value: ["event": event]))
                wrote = true
            case let reminder as Reminder:
                realm.add(Ignorance(value: ["reminder": reminder]))
                wrote = true
            default:
                break
            }
        }

        return wrote
    }

    @discardableResult
    static func unignore(_ thing: Temporality) -> Bool {
        guard   let ignorance = of(thing) else {
            return false
        }
        ignorance.delete()
        return true
    }
}
