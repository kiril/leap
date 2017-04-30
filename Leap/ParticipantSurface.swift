//
//  ParticipantSurface.swift
//  Leap
//
//  Created by Kiril Savino on 4/30/17.
//  Copyright © 2017 Single Leap, Inc. All rights reserved.
//

import Foundation

class ParticipantSurface: Surface, ModelLoadable {
    override var type: String { return "participant" }

    let name       = SurfaceString()
    let engagement = SurfaceProperty<Engagement>()
    let isMe       = SurfaceBool()

    static func load(fromModel event: LeapModel) -> Surface? {
        return load(byId: event.id)
    }

    static func load(byId participantId: String) -> ParticipantSurface? {
        guard let part = Participant.by(id: participantId) else {
            return nil
        }

        let surface = ParticipantSurface(id: participantId)
        let bridge = SurfaceModelBridge(id: participantId, surface: surface)

        bridge.reference(part, as: "participant")

        bridge.readonlyBind(surface.name) { (m:LeapModel) -> String? in
            guard let participant = m as? Participant else { return nil }
            return participant.nameOrEmail
        }

        bridge.readonlyBind(surface.engagement) { (m:LeapModel) -> Engagement in
            guard let participant = m as? Participant else { return .none }
            return participant.engagement
        }

        bridge.readonlyBind(surface.isMe) { (m:LeapModel) -> Bool in
            guard let participant = m as? Participant else { return false }
            return participant.isMe
        }

        surface.store = bridge
        bridge.populate(surface)
        return surface
    }
}
