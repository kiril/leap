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
        didSet { setBorderColor() }
    }

    private func setBorderColor() {
        self.layer.borderColor = borderColor.cgColor
        self.layer.borderWidth = 1.0
    }

    private func setup() {
        setBorderColor()
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
}
