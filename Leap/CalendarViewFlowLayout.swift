//
//  CalendarViewFlowLayout.swift
//  Leap
//
//  Created by Chris Ricca on 3/16/17.
//  Copyright © 2017 Kiril Savino. All rights reserved.
//

import UIKit

class CalendarViewFlowLayout: UICollectionViewFlowLayout {
    let itemHeight: CGFloat = 120

    override init() {
        super.init()
        setupLayout()
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setupLayout()
    }

    func setupLayout() {
        minimumInteritemSpacing = 0
        minimumLineSpacing = 1
        scrollDirection = .vertical
    }

    func itemWidth() -> CGFloat {
        return collectionView!.frame.width
    }

//    override var estimatedItemSize: CGSize {
//        set {
//            self.estimatedItemSize = CGSize(width: itemWidth(), height: itemHeight)
//        }
//        get {
//            return CGSize(width: itemWidth(), height: itemHeight)
//        }
//    }

    override func targetContentOffset(forProposedContentOffset proposedContentOffset: CGPoint) -> CGPoint {
        return collectionView!.contentOffset
    }
}
