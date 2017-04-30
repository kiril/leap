//
//  EventDetailView.swift
//  Leap
//
//  Created by Kiril Savino on 4/27/17.
//  Copyright © 2017 Single Leap, Inc. All rights reserved.
//

import UIKit

class EventDetailView: EventDisplayView {
    @IBOutlet weak var separator1: UIView!

    override func configure(with event: EventSurface) {
        super.configure(with: event)
        titleLabel.text = event.title.value
        timeLabel.text = event.isRecurring.value ? event.recurringTimeRange.value : "From \(event.timeRange.value)"
        if let location = event.locationSummary.rawValue {
            locationContainer?.isHidden = false
            locationLabel.text = location
        } else {
            locationContainer?.isHidden = true
        }
        invitationSummaryLabel.text = event.invitationSummary.value
        var detail = event.detail.value
        if detail.characters.isEmpty {
            detailLabel.text = "No Detail Available"
            detailLabel.font = UIFont.italicSystemFont(ofSize: detailLabel.font.pointSize)
            detailLabel.textAlignment = NSTextAlignment.center
            detailLabel.textColor = UIColor.projectLightGray
        } else {
            detailLabel.font = UIFont.systemFont(ofSize: detailLabel.font.pointSize)
            detailLabel.textAlignment = NSTextAlignment.left
            detailLabel.textColor = UIColor.projectDarkGray
            detailLabel.text = detail
        }

        separator1.backgroundColor = UIColor.projectLightGray
    }

    class func instanceFromNib() -> EventDetailView {
        return UINib(nibName: "EventDetailView", bundle: nil).instantiate(withOwner: nil, options: nil)[0] as! EventDetailView
    }
}
