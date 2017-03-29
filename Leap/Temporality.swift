//
//  Temporality.swift
//  Leap
//
//  Created by Kiril Savino on 3/22/17.
//  Copyright © 2017 Single Leap, Inc. All rights reserved.
//

import Foundation
import RealmSwift



protocol Temporality {
    var externalId: String? { get }
    var date: Date? { get }
    var isRecurring: Bool { get }
    var recurrence: Recurrence? { get set }
    var participants: List<Participant> { get }
    var me: Participant? { get }
    var externalURL: String? { get set }
    var alarms: List<Alarm> { get }
    var duration: TimeInterval { get }
    var calendar: LegacyCalendar? { get set }
}

extension Temporality {
    var me: Participant? {
        for participant in participants {
            if let person = participant.person, person.isMe {
                return participant
            }
        }

        return nil
    }
}

class _TemporalBase: LeapModel {
    dynamic var calendar: LegacyCalendar? = nil
    dynamic var externalId: String? = nil
    dynamic var title: String = ""
    dynamic var detail: String? = nil
    dynamic var recurrence: Recurrence?
    dynamic var externalURL: String?
    let alarms = List<Alarm>()
    let participants = List<Participant>()
    let sourceCalendars = List<LegacyCalendar>()

    var isRecurring: Bool { return recurrence != nil }
}
