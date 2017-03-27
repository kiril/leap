//
//  Series.swift
//  Leap
//
//  Created by Kiril Savino on 3/27/17.
//  Copyright © 2017 Single Leap, Inc. All rights reserved.
//

import Foundation
import RealmSwift

class Series: LeapModel {
    dynamic var creator: Person?
    dynamic var title: String = ""
    dynamic var template: EventTemplate?
    dynamic var recurrence: Recurrence?

    let events = LinkingObjects(fromType: Event.self, property: "series")
}
