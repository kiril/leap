//
//  WeekOverviewDayListingView.swift
//  Leap
//
//  Created by Chris Ricca on 4/4/17.
//  Copyright © 2017 Single Leap, Inc. All rights reserved.
//

import UIKit

class WeekOverviewDayListingView: UIView, NibLoadableView {
    @IBOutlet weak var dayNumberLabel: UILabel!
    @IBOutlet weak var dayNameLabel: UILabel!
    @IBOutlet weak var borderView: UIView!

    @IBOutlet weak var daytimeBusynessIndicator: NestedCircleView!
    @IBOutlet weak var eveningBusynessIndicator: NestedCircleView!

    @IBOutlet weak var daytimeIconLabel: UILabel!
    @IBOutlet weak var eveningIconLabel: UILabel!


    var labelColor: UIColor = UIColor.black {
        didSet { updateColors() }
    }

    var isBold: Bool = false {
        didSet { updateFont() }
    }

    var isSelected: Bool = false {
        didSet { updateBorder() }
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setup()
    }

    private func setup() {
        setupUsingNibContent()
        daytimeIconLabel.textColor = UIColor.projectLighterGray
        eveningIconLabel.textColor = UIColor.projectLighterGray
    }

    private func updateColors() {
        dayNumberLabel.textColor = labelColor
        dayNameLabel.textColor = labelColor
    }

    private func updateFont() {
        update(label: dayNumberLabel, toBold: isBold)
        update(label: dayNameLabel, toBold: isBold)
    }

    private func updateBorder() {
        clipsToBounds = false
        borderView.clipsToBounds = false
        borderView.layer.cornerRadius = 5.0
        borderView.layer.borderWidth = 2.0
        borderView.layer.borderColor = isSelected ? UIColor.projectLighterGray.cgColor : UIColor.clear.cgColor
        borderView.backgroundColor = isSelected ? UIColor.white : UIColor.clear
    }

    private func update(label: UILabel, toBold bold: Bool) {
        label.font = label.font.toSystemVersion(withBold: bold)
    }
}
