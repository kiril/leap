//
//  DayScheduleTitleView.swift
//  Leap
//
//  Created by Chris Ricca on 3/29/17.
//  Copyright © 2017 Single Leap, Inc. All rights reserved.
//

import UIKit

class DayScheduleTitleView: UIView {
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var subtitleLabel: UILabel!

    override func awakeFromNib() {
        setup()
    }

    private func setup() {
        titleLabel.textColor = UIColor.projectDarkerGray
        subtitleLabel.textColor = UIColor.projectDarkerGray
    }
}
