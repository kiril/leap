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

    func configure(with reminder: ReminderCellDisplayable) {
        titleLabel.text = reminder.titleForCell

        if reminder is ReminderSurface {
            // ugh. hacky way to detect this, but this whole reminder vs. placeholder thing is feeling a bit cobbled together...
            titleLabel.textColor = UIColor.projectDarkGray
        } else {
            titleLabel.textColor = UIColor.projectLightGray
        }
    }

    private func setup() {
        self.contentView.translatesAutoresizingMaskIntoConstraints = false
        self.translatesAutoresizingMaskIntoConstraints = false
    }

}

protocol ReminderCellDisplayable {
    var titleForCell: String { get }
}

extension ReminderSurface: ReminderCellDisplayable {
    var titleForCell: String {
        switch self.reminderType.value {
        case .day:
            return title.value
        case .time:
            return "\(timeRange.value)  \(title.value)"
        case .event:
            return "\(eventTime.value)  \(title.value)"
        default:
            fatalError()
        }
    }
}

extension NoRemindersPlaceholderObject: ReminderCellDisplayable {
    var titleForCell: String { return "No Reminders" }
}

