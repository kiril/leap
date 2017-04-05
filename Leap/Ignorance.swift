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
    dynamic var person: Person?
    dynamic var event: Event?
    dynamic var reminder: Reminder?

    static func of(_ thing: Temporality, by person: Person) -> Ignorance? {
        let realm = Realm.user()
        let query = realm.objects(Ignorance.self)
        switch thing {
        case let event as Event:
            return query.filter("person = %@ AND event = %@", person, event).first
        case let reminder as Reminder:
            return query.filter("person = %@ AND reminder = %@", person, reminder).first
        default:
            return nil
        }
    }

    @discardableResult
    static func ignore(_ thing: Temporality, for person: Person) -> Bool {
        if let _ = of(thing, by: person) {
            return false
        }
        let realm = Realm.user()
        var wrote: Bool = false
        try! realm.write {
            switch thing {
            case let event as Event:
                realm.add(Ignorance(value: ["person": person, "event": event]))
                wrote = true
            case let reminder as Reminder:
                realm.add(Ignorance(value: ["person": person, "reminder": reminder]))
                wrote = true
            default:
                break
            }
        }
        return wrote
    }
}
