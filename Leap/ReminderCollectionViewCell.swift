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

    var day: GregorianDay!

    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        setup()
    }

    func configure(with reminder: ReminderCellDisplayable, day: GregorianDay) {
        titleLabel.text = reminder.titleForCell(on: day)
        self.day = day

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
    func titleForCell(on day: GregorianDay) -> String
}

extension ReminderSurface: ReminderCellDisplayable {
    func titleForCell(on day: GregorianDay) -> String {
        switch self.reminderType.value {
        case .day:
            return title.value
        case .time:
            return "\(formatDuration(viewedFrom: day)!)  \(title.value)"
        case .event:
            return "\(formatEventDuration(viewedFrom: day)!)  \(title.value)"
        default:
            fatalError()
        }
    }
}

extension NoRemindersPlaceholderObject: ReminderCellDisplayable {
    func titleForCell(on day: GregorianDay) -> String { return "No Headlines" }
}

