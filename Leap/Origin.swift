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
    case share
    case subscription
    case personal
    case unknown

    func winner(vs other: Origin) -> Origin {
        switch self {
        case .invite:
            return self

        default:
            switch other {
            case .invite:
                return other

            default:
                return self
            }
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
