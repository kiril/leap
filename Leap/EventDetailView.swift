//
//  EventDetailView.swift
//  Leap
//
//  Created by Kiril Savino on 4/27/17.
//  Copyright © 2017 Single Leap, Inc. All rights reserved.
//

import UIKit

class EventDetailView: EventDisplayView {

    override func configure(with event: EventSurface) {
        super.configure(with: event)
        timeLabel.text = event.isRecurring.value ? event.recurringTimeRange.value : event.timeRange.value
    }

    class func instanceFromNib() -> EventDetailView {
        return UINib(nibName: "EventDetailView", bundle: nil).instantiate(withOwner: nil, options: nil)[0] as! EventDetailView
    }
}
