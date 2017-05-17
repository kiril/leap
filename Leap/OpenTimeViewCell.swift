//
//  OpenTimeViewCell.swift
//  Leap
//
//  Created by Chris Ricca on 4/20/17.
//  Copyright © 2017 Single Leap, Inc. All rights reserved.
//

import UIKit

protocol OpenTimeViewCellDelegate: class {
    func updatedTimePerspective(on cell: OpenTimeViewCell, for openTime: OpenTimeViewModel)
}

class OpenTimeViewCell: UICollectionViewCell {
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var timeProgressView: TimeProgressView!
    @IBOutlet weak var timeProgressViewHeightConstraint: NSLayoutConstraint!

    weak var delegate: OpenTimeViewCellDelegate?

    private var timeObserver: TimeRangeObserver?

    fileprivate var openTime: OpenTimeViewModel?

    func configure(with openTime: OpenTimeViewModel) {
        self.openTime = openTime

        titleLabel.text = openTime.timeRange + "    open"

        updateTimeDisplay(forOpenTime: openTime)

        if let range = openTime.range {
            timeObserver = TimeRangeObserver(range: range)
            timeObserver?.delegate = self
        }
    }

    fileprivate func updateTimeDisplay(forOpenTime openTime: OpenTimeViewModel) {
        switch openTime.perspective {
        case .past:
            contentView.alpha = 0.5
            timeProgressViewHeightConstraint.constant = 0

        case .current:
            contentView.alpha = 1.0
            timeProgressViewHeightConstraint.constant = 8
            let now = Date()
            timeProgressView.setProgress(progress: CGFloat(now.percentElapsed(withinRange: openTime.range!)),
                                         withEdgeBuffer: 0.02)

        case .future:
            contentView.alpha = 1.0
            timeProgressViewHeightConstraint.constant = 0
            timeProgressView.progress = 1.0
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

        timeProgressView.borderColor = UIColor.projectLightGray
        timeProgressView.progressColor = UIColor.projectLightGray
        timeProgressView.backgroundColor = UIColor.white
        timeProgressView.endCapType = .rounded
    }
}

extension OpenTimeViewCell: TimeRangeObserverDelegate {
    func didObserveTimePerspectiveChange(on observer: TimeRangeObserver) {
        guard let openTime = openTime else { return }
        delegate?.updatedTimePerspective(on: self, for: openTime)
    }

    func didObserveMinuteChangeWhenCurrent(on observer: TimeRangeObserver) {
        guard let openTime = openTime else { return }
        UIView.animate(withDuration: 0.2) { [weak self] in
            self?.updateTimeDisplay(forOpenTime: openTime)
            self?.setNeedsLayout()
            self?.layoutIfNeeded()
        }

    }
}
