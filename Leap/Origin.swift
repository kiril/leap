//
//  Origin.swift
//  Leap
//
//  Created by Kiril Savino on 5/16/17.
//  Copyright © 2017 Single Leap, Inc. All rights reserved.
//

import Foundation


enum Origin: String {
    case invite
    case personal
    case share
    case subscription
    case unknown

    func winner(vs other: Origin) -> Origin {
        if self.rawValue < other.rawValue {
            return self
        } else if other.rawValue < rawValue {
            return other
        } else {
            return self
        }
    }
}

protocol Originating {
    var origin: Origin { get set }
    var originString: String { get set }
}

extension Originating {
    var origin: Origin {
        get { return Origin(rawValue: originString)! }
        set { originString = newValue.rawValue }
    }

    mutating func updateToBestOrigin(with origin: Origin) {
        let mine = self.origin
        let best = mine.winner(vs: origin)
        if best != mine {
            self.origin = best
        }
    }
}
