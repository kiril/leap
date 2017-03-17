//
//  OpenTimeViewModel.swift
//  Leap
//
//  Created by Chris Ricca on 3/17/17.
//  Copyright © 2017 Single Leap, Inc. All rights reserved.
//

import Foundation

struct OpenTimeViewModel {
    let startTime: Date?
    let endTime: Date?

    var timeRange: String {
        return "10 - 11pm"
    }

    init(startTime: Date?, endTime: Date?) {
        self.startTime = startTime
        self.endTime = endTime
    }

    init() {
        self.init(startTime: nil, endTime: nil)
    }
}
