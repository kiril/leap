//
//  DeviceAccount.swift
//  Leap
//
//  Created by Kiril Savino on 3/22/17.
//  Copyright © 2017 Single Leap, Inc. All rights reserved.
//

import Foundation
import RealmSwift

enum AccountType: String {
    case local      = "local"
    case exchange   = "exchange"
    case calDAV     = "calDAV"
    case mobileMe   = "mobileMe"
    case subscribed = "subscribed"
    case birthdays  = "birthdays"
    case facebook   = "facebook"
}

class DeviceAccount: LeapModel {
    dynamic var accountTypeString: String = AccountType.local.rawValue
    var accountType: AccountType {
        get { return AccountType(rawValue: accountTypeString)! }
        set { accountTypeString = newValue.rawValue }
    }
    dynamic var title: String = ""
}
