//
//  OpenTimeViewModel.swift
//  Leap
//
//  Created by Chris Ricca on 3/17/17.
//  Copyright © 2017 Single Leap, Inc. All rights reserved.
//

import Foundation

struct OpenTimeViewModel: Equatable {
    let startTime: Date?
    let endTime: Date?
    var occurenceIndex: Int

    init(startTime: Date?, endTime: Date?, occurenceIndex: Int) {
        self.startTime = startTime
        self.endTime = endTime
        self.occurenceIndex = occurenceIndex
    }

    init() {
        self.init(startTime: nil, endTime: nil, occurenceIndex: 0)
    }

    static func == (lhs: OpenTimeViewModel, rhs: OpenTimeViewModel) -> Bool {
        return lhs.startTime == rhs.startTime && lhs.endTime == rhs.endTime
    }

    var timeRange: String {
        let calendar = Calendar.current

        guard let startTime = startTime else {
            guard let endTime = endTime else { return "" }

            let to = calendar.formatDisplayTime(from: endTime, needsAMPM: true)
            return "Until \(to)"
        }
        guard let endTime = endTime else {
            let from = calendar.formatDisplayTime(from: startTime, needsAMPM: true)
            return "\(from) onwards"
        }

        let startHour = calendar.component(.hour, from: startTime)
        let endHour = calendar.component(.hour, from: endTime)

        let crossesNoon = startHour < 12 && endHour >= 12

        let from = calendar.formatDisplayTime(from: startTime, needsAMPM: crossesNoon)
        let to = calendar.formatDisplayTime(from: endTime, needsAMPM: true)

        return "\(from)-\(to)"
    }

}
