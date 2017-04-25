//
//  ReminderCollectionViewCell.swift
//  Leap
//
//  Created by Chris Ricca on 4/25/17.
//  Copyright © 2017 Single Leap, Inc. All rights reserved.
//

import UIKit

class ReminderCollectionViewCell: UICollectionViewCell {

    @IBOutlet weak var titleLabel: UILabel!

    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        setup()
    }

    func configure(with reminder: ReminderSurface) {
        titleLabel.text = reminder.title.value
    }

    private func setup() {
        self.contentView.translatesAutoresizingMaskIntoConstraints = false
        self.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.textColor = UIColor.projectDarkGray
    }

}
