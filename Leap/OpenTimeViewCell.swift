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
        switch openTime.perspective {
        case .past:
            contentView.alpha = 0.5
        case .current, .future:
            contentView.alpha = 1.0
        }
    }

    override func awakeFromNib() {
        super.awakeFromNib()
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

        titleLabel.textColor = UIColor.projectDarkGray
    }
}
