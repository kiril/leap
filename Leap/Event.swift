//
//  Event.swift
//  Leap
//
//  Created by Kiril Savino on 3/22/17.
//  Copyright © 2017 Single Leap, Inc. All rights reserved.
//

import RealmSwift
import Foundation

enum EventDisplayType: String {
    case schedule = "schedule"
    case headline = "headline"
}

enum EventModality: String {
    case unknown  = "unknown"
    case inPerson = "in_person"
    case video    = "video"
    case phone    = "phone"
    case chat     = "chat"
}

enum Firmness: String {
    case firm
    case soft
    case unknown
}

/**
 * Here's our core!
 */
class Event: _TemporalBase, Temporality, CalendarLinkable, Alarmable, Fuzzy {
    dynamic var startTime: Int = 0
    dynamic var endTime: Int = 0
    dynamic var modalityString: String = EventModality.unknown.rawValue
    dynamic var agenda: Checklist? = nil
    dynamic var firmnessString: String = Firmness.firm.rawValue
    dynamic var displayTypeString: String = EventDisplayType.schedule.rawValue
    dynamic var isTentative: Bool = false
    dynamic var arrivalOffset: Int = 0
    dynamic var arrivalRefefence: Event? = nil
    dynamic var departureOffset: Int = 0
    dynamic var departureReference: Event? = nil

    let channels = List<Channel>()
    let venues = List<Venue>()
    let reservations = List<Reservation>()

    var modality: EventModality {
        get { return EventModality(rawValue: modalityString)! }
        set { modalityString = newValue.rawValue }
    }

    var firmness: Firmness {
        get { return Firmness(rawValue: firmnessString)! }
        set { firmnessString = newValue.rawValue }
    }

    var displayType: EventDisplayType {
        get { return EventDisplayType(rawValue: displayTypeString)! }
        set { displayTypeString = newValue.rawValue }
    }

    var date: Date? { return Date(timeIntervalSinceReferenceDate: Double(startTime)) }
    var startDate: Date { return Date(timeIntervalSinceReferenceDate: Double(startTime)) }
    var endDate: Date { return Date(timeIntervalSinceReferenceDate: Double(endTime)) }
    var time: TimeInterval { return Double(startTime) }

    override static func indexedProperties() -> [String] {
        return ["venue", "room", "startTime", "endTime", "participants", "statusString", "hash"]
    }

    var duration: TimeInterval {
        return Double(self.endTime - self.startTime)
    }

    var startHour: Int { return Calendar.current.component(.hour, from: self.startDate) }
    var startMinute: Int { return Calendar.current.component(.minute, from: self.startDate) }

    var durationMinutes: Int {
        let durationInSeconds = endDate.secondsSinceReferenceDate - startDate.secondsSinceReferenceDate
        return durationInSeconds / 60
    }

    func calculateFuzzyHash() -> Int {
        return "\(title)_\(startTime)_\(endTime)_\(participants)".hashValue
    }

    func isDuplicateOfExisting() -> Bool {
        let query = Realm.user().objects(Event.self).filter("title = %@ AND startTime = %d", title, startTime)
        return query.first != nil
    }

    static func on(_ day: GregorianDay) -> Results<Event> {
        let start = Calendar.current.startOfDay(for: day)
        let end = Calendar.current.startOfDay(for: day.dayAfter)
        return between(start, and: end)
    }

    static func between(_ starting: Date,
                        and before: Date,
                        withStatus status: ObjectStatus = .active,
                        withDisplayType displayType: EventDisplayType? = nil) -> Results<Event> {

        var displayTypeQuery = ""
        if let displayType = displayType {
            displayTypeQuery = "displayTypeString = \(displayType.rawValue) AND"
        }

        let queryString = displayTypeQuery + "statusString = %@ AND ((startTime >= %d AND startTime < %d) OR (endTime >= %d AND endTime <= %d))"
        let predicate = NSPredicate(format: queryString,
                                    status.rawValue,
                                    starting.secondsSinceReferenceDate,
                                    before.secondsSinceReferenceDate,
                                    starting.secondsSinceReferenceDate,
                                    before.secondsSinceReferenceDate)
        
        return Realm.user().objects(Event.self).filter(predicate).sorted(byKeyPath: "startTime")
        // TODO: also spanning this range??? (notes???)
    }

    static func by(id: String) -> Event? {
        return fetch(id: id)
    }
}
