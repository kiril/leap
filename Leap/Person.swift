//
//  Person.swift
//  Leap
//
//  Created by Kiril Savino on 3/24/17.
//  Copyright © 2017 Single Leap, Inc. All rights reserved.
//

import Foundation
import RealmSwift


enum PersonRelationship: String {
    case unknown = "unknown"
    case myself  = "self"
    case contact = "contact"
}

class Email: Object, ValueWrapper {
    dynamic var raw: String = ""
}

class Phone: Object, ValueWrapper {
    dynamic var raw: String = ""
}


class Person: LeapModel {
    dynamic var givenName: String?
    dynamic var familyName: String?
    dynamic var organization: String?
    dynamic var title: String?
    dynamic var notes: String?
    dynamic var birthDate: Date?
    dynamic var url: String?
    dynamic var isMe: Bool = false
    dynamic var work: Location?
    dynamic var home: Location?

    let emails = List<Email>()
    let numbers = List<Phone>()
    let addresses = List<Address>()

    var name: String? {
        if let f = givenName, let l = familyName {
            return "\(f) \(l)"
        } else if let f = givenName {
            return f
        } else if let l = familyName {
            return l
        }
        return nil
    }

    func setNameComponents(from fullName: String?) {
        if let fullName = fullName {
            if fullName.contains("@") {
                self.emails.append(Email(value: ["raw": fullName]))
            } else {
                let bits = fullName.components(separatedBy: " ")
                if bits.count == 2 {
                    self.givenName = bits[0]
                    self.familyName = bits[1]
                } else {
                    self.givenName = bits[0]
                }
            }
        }
    }

    override static func indexedProperties() -> [String] {
        return ["url", "emails", "isMe"]
    }

    static func me() -> Person? {
        return Realm.user().objects(Person.self).filter("isMe = true").first
    }

    static func by(id: String) -> Person? {
        return fetch(id: id)
    }

    static func by(email: String) -> Person? {
        return Realm.user().objects(Person.self).filter("email = %@", email).first
    }
}
