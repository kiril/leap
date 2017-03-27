//
//  Organization.swift
//  Leap
//
//  Created by Kiril Savino on 3/27/17.
//  Copyright © 2017 Single Leap, Inc. All rights reserved.
//

import Foundation
import RealmSwift

class Organization: LeapModel {
    dynamic var name: String = ""

    let members = List<Person>()
}
