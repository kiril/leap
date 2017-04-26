//
//  SpacingSectionController.swift
//  Leap
//
//  Created by Chris Ricca on 4/26/17.
//  Copyright © 2017 Single Leap, Inc. All rights reserved.
//

import Foundation
import IGListKit

class SpacingSectionController: IGListSectionController, IGListSectionType {

    var placeholderObject: VerticalSpacingPlaceholderObject?

    func numberOfItems() -> Int {
        return 1
    }

    func sizeForItem(at index: Int) -> CGSize {
        guard let width = collectionContext?.containerSize.width,
              let height = placeholderObject?.height else {
                return CGSize.zero
        }

        return CGSize(width: width, height: height)
    }

    func cellForItem(at index: Int) -> UICollectionViewCell {
        guard let height = placeholderObject?.height else {
            fatalError("No placeholder object found")
        }

        let cell = collectionContext?.dequeueReusableCell(of: VerticalSpacingCollectionViewCell.self, for: self, at: index) as! VerticalSpacingCollectionViewCell

        cell.height = height
        return cell
    }

    func didUpdate(to object: Any) {
        if let p = object as? VerticalSpacingPlaceholderObject {
            placeholderObject = p
        }
    }
    
    func didSelectItem(at index: Int) {
    }

}
