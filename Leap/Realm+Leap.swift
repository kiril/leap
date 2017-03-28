//
//  Realm+Leap.swift
//  Leap
//
//  Created by Kiril Savino on 3/24/17.
//  Copyright © 2017 Single Leap, Inc. All rights reserved.
//

import Foundation
import RealmSwift


protocol ValueWrapper {
    associatedtype T
    var value: T { get }
}

extension ValueWrapper {
    static func primaryKey() -> String? {
        return "value"
    }
}



class IntWrapper: Object, ValueWrapper {
    var value: Int = 0

    static func of(_ int: Int) -> IntWrapper {
        return IntWrapper(value: ["value": int])
    }

    static func of(num: NSNumber) -> IntWrapper {
        return IntWrapper(value: ["value": num.intValue])
    }
}


extension Realm {

    static func inMemory() -> Realm {
        return try! Realm(configuration: Realm.Configuration(inMemoryIdentifier: "Leap"))
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

    static func user() -> Realm {
        return inMemory()
    }
}
