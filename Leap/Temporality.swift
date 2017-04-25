//
//  Temporality.swift
//  Leap
//
//  Created by Kiril Savino on 3/22/17.
//  Copyright © 2017 Single Leap, Inc. All rights reserved.
//

import Foundation
import RealmSwift
import EventKit


enum Origin: String {
    case invite
    case share
    case subscription
    case personal
    case unknown
}


protocol Temporality: Particible {
    var id: String { get }
    var title: String { get }
    var detail: String? { get }
    var externalId: String? { get }
    var origin: Origin { get set }

    var date: Date? { get }
    var time: TimeInterval { get }
    var duration: TimeInterval { get }

    var locationString: String? { get }
    var legacyTimeZone: TimeZone? { get }
    var remoteCreated: Date? { get }
    var remoteLastModified: Date? { get }

    var isRecurring: Bool { get }
    var wasDetached: Bool { get }

    var externalURL: String? { get set }
    var alarms: List<Alarm> { get }
    var linkedCalendarIds: List<StringWrapper> { get }

    var seriesId: String? { get set }
    var template: Template? { get set }

    func isBetterVersionOf(_ other: Temporality) -> Bool
    func isDuplicateOfExisting() -> Bool

    var status: ObjectStatus { get set }
}

extension Temporality {

    func isBetterVersionOf(_ old: Temporality) -> Bool {

        // for recurring events, we want the earliest instance
        if old.isRecurring, !wasDetached {
            if Calendar.current.isDate(self.date!, after: old.date!) {
                return false // this is just a new instance of the same old one
            } else if Calendar.current.isDate(self.date!, before: old.date!) {
                return true // the new one is in fact earlier and should override as the actual original
            }
        }

        // now let's figure out if we just don't have a change
        var hasChanged = false
        let oldLastModified = old.remoteLastModified
        let newLastModified = remoteLastModified
        if newLastModified != nil, oldLastModified == nil {
            hasChanged = true
        } else if let olm = oldLastModified,
            let nlm = newLastModified,
            Calendar.current.isDate(nlm, after: olm) {
            hasChanged = true
        }

        if hasChanged {
            return true // cool, this is an updated version

        } else {
            return false // just use the old one
        }
    }
}

class _TemporalBase: LeapModel {
    dynamic var externalId: String? = nil
    dynamic var title: String = ""
    dynamic var detail: String? = nil
    dynamic var externalURL: String?
    dynamic var remoteCreated: Date? = nil
    dynamic var remoteLastModified: Date? = nil
    dynamic var seriesId: String? = nil
    dynamic var wasDetached: Bool = false
    dynamic var locationString: String? = nil
    dynamic var legacyTimeZone: TimeZone?
    dynamic var template: Template?
    dynamic var originString: String = Origin.unknown.rawValue

    let seriesEventNumber = RealmOptional<Int>()

    let alarms = List<Alarm>()
    let participants = List<Participant>()
    let linkedCalendarIds = List<StringWrapper>()

    var isRecurring: Bool { return seriesId != nil }

    var origin: Origin {
        get { return Origin(rawValue: originString)! }
        set { originString = newValue.rawValue }
    }
}
