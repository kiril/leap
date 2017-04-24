//
//  ReminderSurface.swift
//  Leap
//
//  Created by Chris Ricca on 4/24/17.
//  Copyright © 2017 Single Leap, Inc. All rights reserved.
//

import Foundation

class ReminderSurface: Surface, ModelLoadable {
    override var type: String { return "reminder" }

    let title                  = SurfaceString(minLength: 1)

    static func load(fromModel reminder: LeapModel) -> Surface? {
        return load(byId: reminder.id)
    }

    static func load(byId reminderId: String) -> ReminderSurface? {
        guard let reminder: Reminder = Reminder.by(id: reminderId) else {
            return nil
        }

        let surface = ReminderSurface(id: reminderId)
        let bridge = SurfaceModelBridge(id: reminderId, surface: surface)

        bridge.reference(reminder, as: "reminder")

        bridge.bind(surface.title)

        surface.store = bridge
        bridge.populate(surface)
        return surface
    }

}
