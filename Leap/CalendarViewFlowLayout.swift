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
        minimumLineSpacing = 15

        scrollDirection = .vertical
    }

}
