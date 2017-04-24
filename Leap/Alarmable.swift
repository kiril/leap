//
//  Alarmable.swift
//  Leap
//
//  Created by Kiril Savino on 4/24/17.
//  Copyright © 2017 Single Leap, Inc. All rights reserved.
//

import Foundation
import RealmSwift

protocol Alarmable {
    var alarms: List<Alarm> { get }
}

extension Alarmable {
    func addAlarms(_ alarms: [Alarm]) {
        for alarm in alarms {
            if !alarms.contains(alarm) {
                self.alarms.append(alarm)
            }
        }
    }
}

