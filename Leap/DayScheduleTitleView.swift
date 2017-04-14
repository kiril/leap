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

    enum DayScheduleTitleViewStyle {
        case normal, light, bold
    }

    var style = DayScheduleTitleViewStyle.normal {
        didSet {
            updateFonts()
        }
    }

    private func setup() {
        updateFonts()
    }

    private func updateFonts() {
        var color: UIColor!

        switch style {
        case .normal:
            color = UIColor.projectDarkerGray
        case .bold:
            color = UIColor.projectPurple
        case .light:
            color = UIColor.projectLightGray;
        }

        titleLabel.textColor = UIColor.projectDarkerGray
        subtitleLabel.textColor = color
    }
}
