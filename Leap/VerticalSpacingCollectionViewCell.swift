//
//  VerticalSpacingCollectionViewCell.swift
//  Leap
//
//  Created by Chris Ricca on 4/26/17.
//  Copyright © 2017 Single Leap, Inc. All rights reserved.
//

import UIKit

class VerticalSpacingCollectionViewCell: UICollectionViewCell {
    var height: CGFloat = 10 {
        didSet { updateHeightConstraint() }
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)

        setup()
    }

    override init(frame: CGRect) {
        super.init(frame: frame)

        setup()
    }

    private func setup() {
        updateHeightConstraint()
        self.translatesAutoresizingMaskIntoConstraints = false
        self.contentView.translatesAutoresizingMaskIntoConstraints = false
    }

    private func updateHeightConstraint() {
        self.contentView.heightAnchor.constraint(equalToConstant: height).isActive = true
    }
}
