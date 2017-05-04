//
//  SeriesSurface.swift
//  Leap
//
//  Created by Kiril Savino on 4/14/17.
//  Copyright © 2017 Single Leap, Inc. All rights reserved.
//

import Foundation

class SeriesSurface: Surface, ModelLoadable {
    override var type: String { return "series" }

    let title                  = SurfaceString(minLength: 1)
    let seriesType     = SurfaceProperty<CalendarItemType>()

    func event(for day: GregorianDay) -> EventSurface? {
        let range = TimeRange(start: Calendar.current.startOfDay(for: day), end: Calendar.current.startOfDay(for: day.dayAfter))!
        guard let series = Series.by(id: id), series.recurs(in: range) else { return nil }
        guard let startTime = series.template.startTime(in: range) else { return nil }

        if let event = Event.by(id: series.generateId(for: startTime)) {
            return EventSurface.load(with: event) as? EventSurface
        }

        return RecurringEventSurface.load(with: series, in: range)
    }

    func reminder(for day: GregorianDay) -> ReminderSurface? {
        let range = TimeRange(start: Calendar.current.startOfDay(for: day), end: Calendar.current.startOfDay(for: day.dayAfter))!
        guard let series = Series.by(id: id), series.recurs(in: range) else { return nil }
        guard let startTime = series.template.startTime(in: range) else { return nil }

        if let reminder = Reminder.by(id: series.generateId(for: startTime)) {
            return ReminderSurface.load(with: reminder) as? ReminderSurface
        }

        return RecurringReminderSurface.load(from: series, in: range)
    }

    func recursOn(_ day: GregorianDay) -> Bool {
        guard let series = Series.by(id: id) else {
            return false
        }
        let start = Calendar.current.startOfDay(for: day)
        let end = Calendar.current.startOfDay(for: day.dayAfter)
        return series.recursBetween(start, and: end)
    }

    static func load(with model: LeapModel) -> Surface? {
        guard let series = model as? Series else { return nil }

        let surface = SeriesSurface(id: series.id)
        let bridge = SurfaceModelBridge(id: series.id, surface: surface)
        bridge.reference(series, as: "series")
        bridge.bind(surface.title, to: "title", on: "series")
        bridge.readonlyBind(surface.seriesType) { (model:LeapModel) in
            if let s = model as? Series {
                return s.type
            }
            return nil
        }
        bridge.populate(surface, with: series, as: "series")
        return surface
    }

    static func load(byId seriesId: String) -> SeriesSurface? {
        guard let series:Series = Series.by(id: seriesId) else {
            return nil
        }
        return load(with: series) as? SeriesSurface
    }
}
