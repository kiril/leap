//
//  Channel.swift
//  Leap
//
//  Created by Kiril Savino on 3/24/17.
//  Copyright © 2017 Single Leap, Inc. All rights reserved.
//

import Foundation


enum ChannelType: String {
    case unknown   = "unknown"
    case email     = "email"
    case phone     = "phone"
    case text      = "text"
    case im        = "im"
}


class Channel: LeapModel {
    dynamic var name: String = ""
    dynamic var typeString: String = ChannelType.unknown.rawValue
    dynamic var value: String?

    var type: ChannelType {
        get { return ChannelType(rawValue: typeString)! }
        set { typeString = newValue.rawValue }
    }
}
