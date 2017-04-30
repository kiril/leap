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
    @IBOutlet weak var detailSeparator: UIView!
    @IBOutlet weak var beforeLabel: UILabel!
    @IBOutlet weak var afterLabel: UILabel!
    @IBOutlet weak var separator3: UIView!
    @IBOutlet weak var separator4: UIView!

    var entries: [ScheduleEntry]!

    override func configure(with event: EventSurface) {
        super.configure(with: event)
        titleLabel.text = event.title.value
        timeLabel.text = event.isRecurring.value ? event.recurringTimeRange.value : "From \(event.timeRange.value)"
        timeLabel.textColor = UIColor.projectLightGray

        if let location = event.locationSummary.rawValue {
            locationContainer?.isHidden = false
            if location.looksLikeAnAddress {
                locationLabel.isHidden = true
                locationButton.isHidden = false
                locationButton.setTitle(location, for: .normal)
                locationButton.titleLabel?.numberOfLines = 0
            } else {
                locationLabel.text = location
                locationButton.isHidden = true
                locationLabel.isHidden = false
            }
        } else {
            locationContainer?.isHidden = true
            locationButton.isHidden = true
            locationLabel.isHidden = true
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

        separator1.backgroundColor = UIColor.projectLighterGray
        detailSeparator.backgroundColor = UIColor.projectLighterGray
        separator3.backgroundColor = UIColor.projectLighterGray
        separator4.backgroundColor = UIColor.projectLighterGray

        beforeLabel.textColor = UIColor.projectDarkGray
        afterLabel.textColor = UIColor.projectDarkGray

        configureBeforeAndAfter()
    }

    func configureBeforeAndAfter() {
        var priorEvent: EventSurface? = nil
        var priorOpen: OpenTimeViewModel? = nil
        var afterOpen: OpenTimeViewModel? = nil
        var afterEvent: EventSurface? = nil

        var isBefore = true

        for entry in entries {
            switch entry {
            case let .event(event):
                if event == self.event! {
                    isBefore = false
                    continue

                } else if isBefore {
                    priorEvent = event
                    priorOpen = nil

                } else {
                    afterEvent = event
                    break
                }

            case let .openTime(openTime):
                if isBefore {
                    priorOpen = openTime
                } else {
                    afterOpen = openTime
                }
            }
        }

        if let event = priorEvent, let open = priorOpen {
            beforeLabel.text = "\(event.title.value) ends \(open.durationMinutes) minutes before"
        } else if let event = priorEvent {
            beforeLabel.text = "Immediately follows \(event.title.value)"
        } else {
            beforeLabel.text = "First event of the day"
        }

        if let event = afterEvent, let open = afterOpen {
            afterLabel.text = "\(event.title.value) starts \(open.durationMinutes) minutes after"
        } else if let event = afterEvent {
            afterLabel.text = "Followed immediately by \(event.title.value)"
        } else {
            afterLabel.text = "Last event of the day"
        }
    }

    class func instanceFromNib() -> EventDetailView {
        return UINib(nibName: "EventDetailView", bundle: nil).instantiate(withOwner: nil, options: nil)[0] as! EventDetailView
    }
}
