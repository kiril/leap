//
//  ChecklistItem.swift
//  Leap
//
//  Created by Kiril Savino on 3/27/17.
//  Copyright © 2017 Single Leap, Inc. All rights reserved.
//

import Foundation
import RealmSwift

class ChecklistItem: Object {
    dynamic var title: String = ""
    dynamic var checked: Bool = false
}
