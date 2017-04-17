//
//  Realm+Leap.swift
//  Leap
//
//  Created by Kiril Savino on 3/24/17.
//  Copyright © 2017 Single Leap, Inc. All rights reserved.
//

import Foundation
import RealmSwift


extension Realm {
    static var isInTestMode: Bool { return false }

    static func inMemory(name: String = "Leap") -> Realm {
        return try! Realm(configuration: Realm.Configuration(inMemoryIdentifier: name))
    }

    static func diskBacked() -> Realm {
        let config = Realm.Configuration(
            schemaVersion: 1,
            migrationBlock: { migration, oldSchemaVersion in
                /*
                if (oldSchemaVersion < 1) {
                    // The enumerateObjects(ofType:_:) method iterates
                    // over every Person object stored in the Realm file
                    migration.enumerateObjects(ofType: Person.className()) { oldObject, newObject in
                        // combine name fields into a single field
                        let firstName = oldObject!["firstName"] as! String
                        let lastName = oldObject!["lastName"] as! String
                        newObject!["fullName"] = "\(firstName) \(lastName)"
                    }
                }
                */
            }
        )
        return try! Realm(configuration: config)
    }

    static func temp() -> Realm {
        return inMemory(name: "Temp")
    }

    static func user() -> Realm {
        if isInTestMode {
            return inMemory() // always
        }
        return inMemory() // for now
    }

    static func auth() -> Realm {
        if isInTestMode {
            return inMemory() // always
        }
        return inMemory() // for now
    }

    static func config() -> Realm {
        return inMemory() // for now
    }
}
