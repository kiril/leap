//
//  EventViewCell.swift
//  Leap
//
//  Created by Chris Ricca on 3/16/17.
//  Copyright © 2017 Kiril Savino. All rights reserved.
//

import UIKit

class EventViewCell: UICollectionViewCell {
    @IBOutlet weak var timeLabel: UILabel!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var invitationSummaryLabel: UILabel!

    var borderColor: UIColor = UIColor.black {
        didSet { updateBorderColor() }
    }

    var displayShadow: Bool = false {
        didSet { updateShadow() }
    }

    private func updateBorderColor() {
        self.layer.borderColor = borderColor.cgColor
        self.layer.borderWidth = 1.0
    }

    private func updateShadow() {
        let shadowPath = UIBezierPath(rect: bounds)
        layer.masksToBounds = false;
        layer.shadowColor = UIColor.black.cgColor
        layer.shadowOffset = CGSize(width: 2, height: 2)
        layer.shadowPath = shadowPath.cgPath
        layer.shadowOpacity = displayShadow ? 0.15 : 0
        layer.shadowRadius = 2
    }

    private func setup() {
        updateBorderColor()
        updateShadow()
        updateFonts()
    }

    private func updateFonts() {
        invitationSummaryLabel.textColor = UIColor.projectLightGray
        titleLabel.textColor = UIColor.projectDarkGray
        timeLabel.textColor = UIColor.projectDarkGray
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

    func configure(with event: EventShell) {
        // move out of here to seperate helper classes
        // if this needs to be different
        // for different contexts

        // set values

        timeLabel.text = event.timeRange.value
        titleLabel.text = event.title.value
        invitationSummaryLabel.text = event.invitationSummary.value

        if event.isUnresolved.value == true {
            backgroundColor = UIColor.projectLightBackgroundGray
            borderColor = UIColor.projectLightGray
            displayShadow = true
        } else {
            backgroundColor = UIColor.white
            borderColor = UIColor.projectDarkGray
            displayShadow = false
        }

        if event.perspective.value == .past {
            contentView.alpha = 0.5
            borderColor = UIColor.projectLightGray
        } else {
            contentView.alpha = 1.0
        }

    }

    override func layoutSubviews() {
        super.layoutSubviews()
        updateShadow()
    }
}


extension UIColor {
    static var projectLightBackgroundGray: UIColor {
        return UIColor(r: 246,
                       g: 246,
                       b: 246)
    }

    static var projectLightGray: UIColor {
        return UIColor(r: 189,
                       g: 189,
                       b: 189)
    }

    static var projectDarkGray: UIColor {
        return UIColor(r: 112,
                       g: 112,
                       b: 112)
    }

}
