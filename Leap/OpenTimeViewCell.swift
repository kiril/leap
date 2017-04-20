//
//  OpenTimeViewCell.swift
//  Leap
//
//  Created by Chris Ricca on 4/20/17.
//  Copyright © 2017 Single Leap, Inc. All rights reserved.
//

import UIKit

class OpenTimeViewCell: UICollectionViewCell {
    @IBOutlet weak var titleLabel: UILabel!

    func configure(with openTime: OpenTimeViewModel) {
        titleLabel.text = openTime.timeRange + "    open"
    }

    override func awakeFromNib() {
        setup()
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }


    private func setup() {

        self.contentView.translatesAutoresizingMaskIntoConstraints = false
        self.translatesAutoresizingMaskIntoConstraints = false
    }
}
