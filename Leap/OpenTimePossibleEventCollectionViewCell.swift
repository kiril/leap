//
//  OpenTimePossibleEventCollectionViewCell.swift
//  Leap
//
//  Created by Chris Ricca on 5/2/17.
//  Copyright © 2017 Single Leap, Inc. All rights reserved.
//

import UIKit

class OpenTimePossibleEventCollectionViewCell: UICollectionViewCell {

    @IBOutlet weak var titleLabel: UILabel!

    func configure(with event: EventSurface) {
        let timeText = event.timeRange.value
        let eventName = event.title.value

        titleLabel.text = "\(timeText): \(eventName)"
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
