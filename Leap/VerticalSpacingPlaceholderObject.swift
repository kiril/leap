//
//  VerticalSpacingPlaceholderObject.swift
//  Leap
//
//  Created by Chris Ricca on 4/26/17.
//  Copyright © 2017 Single Leap, Inc. All rights reserved.
//

import Foundation
import IGListKit

class VerticalSpacingPlaceholderObject: IGListDiffable {
    // right now, only going to use 1 placeholder in a list.
    // may need to update this if using > 1 in a collection.

    var height: CGFloat
    var id: String

    init(id: String = "", height: CGFloat = 10) {
        self.height = height
        self.id = id
    }

    func diffIdentifier() -> NSObjectProtocol {
        let idHash = ("VerticalSpacingPlaceholderObject-\(id)").hash
        return NSNumber(value: idHash)
    }

    func isEqual(toDiffableObject object: IGListDiffable?) -> Bool {
        guard let o = object as? VerticalSpacingPlaceholderObject else {
            return false
        }
        return  (o.id == id) && (o.height == height)
    }
}
