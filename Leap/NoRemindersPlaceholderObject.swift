//
//  NoRemindersPlaceholderObject.swift
//  Leap
//
//  Created by Chris Ricca on 4/26/17.
//  Copyright © 2017 Single Leap, Inc. All rights reserved.
//

import Foundation
import IGListKit

class NoRemindersPlaceholderObject: IGListDiffable {
    func diffIdentifier() -> NSObjectProtocol {
        return NSNumber(value: "NoRemindersPlaceholderObject".hash)
    }

    func isEqual(toDiffableObject object: IGListDiffable?) -> Bool {
        return object is NoRemindersPlaceholderObject
    }
}
