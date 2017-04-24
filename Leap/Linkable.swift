//
//  Linkable.swift
//  Leap
//
//  Created by Kiril Savino on 4/24/17.
//  Copyright © 2017 Single Leap, Inc. All rights reserved.
//

import Foundation
import RealmSwift

protocol Linkable {
    var links: List<CalendarLink> { get }
}

extension Linkable {
    func addLink(_ link: CalendarLink) {
        if !links.contains(link) {
            links.append(link)
        }
    }
}
