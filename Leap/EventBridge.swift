//
//  EventBridge.swift
//  Leap
//
//  Created by Kiril Savino on 3/28/17.
//  Copyright © 2017 Single Leap, Inc. All rights reserved.
//

import Foundation

class EventBridge: Bridge {
    var event: ModelReference<Event>

    init(event: Event) {
        self.event = refer(to: event, as: "event")
        super.init(id: "event")
    }

    /*
    override func configure(shell: EventShell) {
        wire(shell.title, to: "title", on: event)
        read(shell.endTime, from: "endTime", on: event)

        defaultReads(shell)

        //read(shell.title) { return self.event.resolve()!.title }
        //read(shell.endTime) { return self.event.resolve()!.endTime }
        //write(shell.title) { value in self.event.resolve()!.title = value as? String }
    }

    static func build(eventId: String) -> EventShell {
    }
 */

    // EventShell.get('eventId')
}
