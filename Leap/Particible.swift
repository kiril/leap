//
//  Particible.swift
//  Leap
//
//  Created by Kiril Savino on 4/24/17.
//  Copyright © 2017 Single Leap, Inc. All rights reserved.
//

import Foundation
import RealmSwift

protocol Particible {
    var participants: List<Participant> { get }
}

extension Particible {
    var me: Participant? {
        for participant in participants {
            if participant.isMe {
                return participant
            }
        }
        return nil
    }

    var organizer: Participant? {
        for participant in participants {
            if participant.ownership == .organizer {
                return participant
            }
        }

        return nil
    }

    var invitees: [Participant] {
        var them: [Participant] = []
        for participant in participants {
            if participant.person != nil && participant.ownership != .organizer {
                them.append(participant)
            }
        }
        return them
    }

    func addParticipants(_ participants: [Participant]) {
        for participant in participants {
            if !self.participants.contains(participant) {
                self.participants.append(participant)
            }
        }

        if self.participants.count == 1 && self.participants[0].isMe && self.participants[0].engagement == .undecided {
            self.participants[0].engagement = .engaged
        }
    }
}
