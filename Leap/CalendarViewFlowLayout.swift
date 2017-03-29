//
//  CalendarViewFlowLayout.swift
//  Leap
//
//  Created by Chris Ricca on 3/16/17.
//  Copyright © 2017 Kiril Savino. All rights reserved.
//

import UIKit

class CalendarViewFlowLayout: UICollectionViewFlowLayout {
    override init() {
        super.init()

        setupLayout()
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)

        setupLayout()
    }

    private func setupLayout() {
        estimatedItemSize = CGSize(width: 200,
                                   height: 200) // can't be wider than (collectionView - insets)

        minimumLineSpacing = 15

        scrollDirection = .vertical
    }
}
