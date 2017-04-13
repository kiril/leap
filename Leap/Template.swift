//
//  Template.swift
//  Leap
//
//  Created by Kiril Savino on 3/27/17.
//  Copyright © 2017 Single Leap, Inc. All rights reserved.
//

import Foundation
import RealmSwift

class Template: LeapModel {
    dynamic var title: String = ""
    dynamic var detail: String?
    dynamic var locationString: String?
    dynamic var agenda: Checklist?
    dynamic var modalityString: String = EventModality.inPerson.rawValue

    let alarms = List<Alarm>()
    let channels = List<Channel>()

    var modality: EventModality {
        get { return EventModality(rawValue: modalityString)! }
        set { modalityString = newValue.rawValue }
    }
}
