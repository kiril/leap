//
//  EKAlarm+Realm.swift
//  Leap
//
//  Created by Kiril Savino on 3/22/17.
//  Copyright © 2017 Single Leap, Inc. All rights reserved.
//

import Foundation
import EventKit
import RealmSwift

extension EKAlarm {
    var alarmType: AlarmType {
        if self.structuredLocation != nil {
            return AlarmType.location
        } else if self.absoluteDate != nil {
            return AlarmType.absolute
        } else {
            return AlarmType.relative
        }
    }

    func asAlarm() -> Alarm {
        let data: [String:Any?] = ["absoluteTime": self.absoluteDate,
                                   "relativeOffset": self.relativeOffset,
                                   "geoFence": GeoFence.from(location: self.structuredLocation),
                                   "typeString": alarmType.rawValue]
        return Alarm(value: data)
    }
}
