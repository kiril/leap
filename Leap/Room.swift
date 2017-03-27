//
//  Room.swift
//  Leap
//
//  Created by Kiril Savino on 3/23/17.
//  Copyright © 2017 Single Leap, Inc. All rights reserved.
//

import Foundation

class Room: Resource {
    dynamic var capacity: Int = 0

    override var type: ResourceType {
        get { return .room }
        set { }
    }
}
