//
//  Auditable.swift
//  Leap
//
//  Created by Kiril Savino on 3/24/17.
//  Copyright © 2017 Single Leap, Inc. All rights reserved.
//

import Foundation
import RealmSwift


enum ObjectStatus: String {
    case active   = "active"
    case archived = "archived"
    case deleted  = "deleted"
}

protocol Auditable {
    var created: Date? { get }
    var updated: Date? { get }
    var deleted: Date? { get }
    var status: ObjectStatus { get set }
}
