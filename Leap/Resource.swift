//
//  Resource.swift
//  Leap
//
//  Created by Kiril Savino on 3/27/17.
//  Copyright © 2017 Single Leap, Inc. All rights reserved.
//

import Foundation


enum AccessRequirement: String {
    case none     = "none"
    case approval = "approval"
    case leadTime = "lead_time"
}

enum ResourceType: String {
    case unknown   = "unknown"
    case room      = "room"
    case equipment = "equipment"
}


class Resource: LeapModel {
    dynamic var name: String = ""
    dynamic var concurrency: Int = 1
    dynamic var venue: Venue?
    dynamic var typeString: String = ResourceType.unknown.rawValue
    dynamic var controller: Person?
    dynamic var accessRequirementString: String = AccessRequirement.none.rawValue
    dynamic var leadTimeHours: Float = 0.0

    var accessRequirement: AccessRequirement {
        get { return AccessRequirement(rawValue: accessRequirementString)! }
        set { accessRequirementString = newValue.rawValue }
    }

    var type: ResourceType {
        get { return ResourceType(rawValue: typeString)! }
        set { typeString = newValue.rawValue }
    }
}
