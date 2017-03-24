//
//  Person.swift
//  Leap
//
//  Created by Kiril Savino on 3/24/17.
//  Copyright © 2017 Single Leap, Inc. All rights reserved.
//

import Foundation


enum PersonRelationship: String {
    case unknown = "unknown"
    case myself  = "self"
    case contact = "contact"
}

class Person: LeapModel {
    dynamic var givenName: String?
    dynamic var familyName: String?
    dynamic var emails: [String]?
    dynamic var numbers: [String]?
    dynamic var addresses: [Address]?
    dynamic var organization: String?
    dynamic var title: String?
    dynamic var notes: String?
    dynamic var birthDate: Date?
    dynamic var isMe: Bool = false
    dynamic var work: Location?
    dynamic var home: Location?

    var name: String { return "\(givenName) \(familyName)" }
}
