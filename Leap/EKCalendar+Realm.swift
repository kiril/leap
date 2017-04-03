//
//  EKCalendar+Realm.swift
//  Leap
//
//  Created by Kiril Savino on 3/22/17.
//  Copyright © 2017 Single Leap, Inc. All rights reserved.
//

import Foundation
import EventKit


extension AccountType {
    static func from(sourceType: EKSourceType) -> AccountType {
        switch sourceType {
        case .local: return AccountType.local
        case .exchange: return AccountType.exchange
        case .calDAV: return AccountType.calDAV
        case .mobileMe: return AccountType.mobileMe
        case .subscribed: return AccountType.subscribed // ??
        case .birthdays: return AccountType.birthdays // ??
        }
    }
}


func hexString(from color: CGColor) -> String {
    let rgb = color.components!
    return String(format: "#%02lX%02lX%02lX", arguments: rgb.map { lroundf(Float($0)) })
}


extension EKSource {
    func asDeviceAccount() -> DeviceAccount {
        return DeviceAccount(value: ["id": self.sourceIdentifier,
                                     "accountTypeString": AccountType.from(sourceType: self.sourceType).rawValue,
                                     "title": self.title])
    }
}


extension EKCalendar {
    func asLegacyCalendar(eventStoreId: String) -> LegacyCalendar {
        print("Woo! Incoming Legacy Calendar!")
        return LegacyCalendar(value: ["id": self.calendarIdentifier,
                                      "eventStoreId": eventStoreId,
                                      "account": self.source.asDeviceAccount(),
                                      "color": hexString(from: self.cgColor),
                                      "writable": self.allowsContentModifications,
                                      "editable": !self.isImmutable,
                                      "relationshipString": self.isSubscribed ? CalendarRelationship.follower.rawValue : CalendarRelationship.owner.rawValue])
    }
}

extension LegacyCalendar {
    func asEKCalendar() -> EKCalendar? {
        let eventStore = EKEventStore()
        return eventStore.calendar(withIdentifier: self.id)
    }
}

