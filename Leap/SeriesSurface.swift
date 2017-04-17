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

    func event(for day: GregorianDay) -> EventSurface? {
        let start = Calendar.current.startOfDay(for: day)
        let end = Calendar.current.startOfDay(for: day.dayAfter)
        if let event = Series.by(id: id)?.event(between: start, and: end) as? Event {
            return EventSurface.load(fromModel: event) as? EventSurface
        }
        return nil
    }

    func recursOn(_ day: GregorianDay) -> Bool {
        guard let series = Series.by(id: id) else {
            return false
        }
        let start = Calendar.current.startOfDay(for: day)
        let end = Calendar.current.startOfDay(for: day.dayAfter)
        return series.recursBetween(start, and: end)
    }

    static func load(fromModel series: LeapModel) -> Surface? {
        return load(byId: series.id)
    }

    static func load(byId seriesId: String) -> SeriesSurface? {
        guard let series:Series = Series.by(id: seriesId) else {
            return nil
        }

        let surface = SeriesSurface(id: seriesId)
        let bridge = SurfaceModelBridge(id: seriesId, surface: surface)
        bridge.reference(series, as: "series")
        bridge.bind(surface.title, to: "title", on: "series")
        return surface
    }
}
