//
//  EventDetailView.swift
//  Leap
//
//  Created by Kiril Savino on 4/27/17.
//  Copyright © 2017 Single Leap, Inc. All rights reserved.
//

import UIKit

protocol EventDetailViewDelegate {
    func nextEventTapped(with event: EventSurface)
    func priorEventTapped(with event: EventSurface)
}

class EventDetailView: UIView {
    var event: EventSurface?
    var nextEvent: EventSurface?
    var priorEvent: EventSurface?

    // header
    @IBOutlet weak var timeLabel: UILabel!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var recurringIcon: UILabel!

    // detail
    @IBOutlet weak var invitationSummaryLabel: UILabel!
    @IBOutlet weak var invitationActionContainer: UIStackView!
    @IBOutlet weak var detailLabel: UILabel!

    // location
    @IBOutlet weak var locationContainer: UIStackView!
    @IBOutlet weak var locationIconLabel: UILabel!
    @IBOutlet weak var locationButton: UIButton!
    @IBOutlet weak var locationLabel: UILabel!

    // response actions
    @IBOutlet weak var yesButton: UIButton!
    @IBOutlet weak var noButton: UIButton!
    @IBOutlet weak var maybeButton: UIButton!
    @IBOutlet weak var remindButton: UIButton!

    // context
    @IBOutlet weak var afterLabel: UILabel!
    @IBOutlet weak var beforeLabel: UILabel!
    @IBOutlet weak var beforeButton: UIButton!
    @IBOutlet weak var afterButton: UIButton!

    @IBOutlet weak var separator1: UIView!
    @IBOutlet weak var detailSeparator: UIView!
    @IBOutlet weak var separator3: UIView!
    @IBOutlet weak var separator4: UIView!
    @IBOutlet weak var alertsLabel: UILabel!

    var entries: [ScheduleEntry]!

    func configure(with event: EventSurface) {
        self.event = event
        recurringIcon.isHidden = !event.isRecurring.value
        timeLabel.text = event.timeRange.value

        updateActionButtons(forEvent: event)
        setup()

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
        alertsLabel.textColor = UIColor.projectLightGray
        afterButton.titleLabel?.textColor = UIColor.projectDarkGray
        beforeButton.titleLabel?.textColor = UIColor.projectDarkGray
        afterButton.titleLabel?.numberOfLines = 0
        beforeButton.titleLabel?.numberOfLines = 0

        configureBeforeAndAfter()
        configureAlerts()
    }

    func configureAlerts() {
        if event!.hasAlarms.value {
            alertsLabel.isHidden = false
            alertsLabel.text = event!.alarmSummary.value
        } else {
            alertsLabel.isHidden = true
        }
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

        self.nextEvent = afterEvent
        self.priorEvent = priorEvent

        if let event = priorEvent, let open = priorOpen {
            let beforeText = NSMutableAttributedString(string: "\(event.title.value) ends \(open.durationMinutes) minutes before")
            beforeText.addAttribute(NSForegroundColorAttributeName, value: UIColor.projectTint, range: NSRange(location: 0, length: event.title.value.utf16.count))
            beforeButton.setAttributedTitle(beforeText, for: .normal)

            beforeLabel.isHidden = true
            beforeButton.isHidden = false

        } else if let event = priorEvent {
            let beforeString = "Immediately follows \(event.title.value)"
            let beforeText = NSMutableAttributedString(string: beforeString)
            let lengthOfTitle = event.title.value.utf16.count
            let range = NSRange(location: beforeString.utf16.count - lengthOfTitle, length: lengthOfTitle)
            beforeText.addAttribute(NSForegroundColorAttributeName, value: UIColor.projectTint, range: range)
            beforeButton.setAttributedTitle(beforeText, for: .normal)

            beforeLabel.isHidden = true
            beforeButton.isHidden = false

        } else {
            beforeLabel.text = "First event of the day"
            beforeLabel.isHidden = false
            beforeButton.isHidden = true
        }

        if let event = afterEvent, let open = afterOpen {
            let afterText = NSMutableAttributedString(string: "\(event.title.value) starts \(open.durationMinutes) minutes after")
            afterText.addAttribute(NSForegroundColorAttributeName, value: UIColor.projectTint, range: NSRange(location: 0, length: event.title.value.utf16.count))
            afterButton.setAttributedTitle(afterText, for: .normal)
            afterLabel.isHidden = true
            afterButton.isHidden = false

        } else if let event = afterEvent {
            let afterString = "Followed immediately by \(event.title.value)"
            let afterText = NSMutableAttributedString(string: afterString)
            let lengthOfTitle = event.title.value.utf16.count
            let range = NSRange(location: afterString.utf16.count - lengthOfTitle, length: lengthOfTitle)
            afterText.addAttribute(NSForegroundColorAttributeName, value: UIColor.projectTint, range: range)
            afterButton.setAttributedTitle(afterText, for: .normal)
            afterLabel.isHidden = true
            afterButton.isHidden = false

        } else {
            afterLabel.text = "Last event of the day"
            afterButton.isHidden = true
            afterLabel.isHidden = false
        }
    }

    class func instanceFromNib() -> EventDetailView {
        return UINib(nibName: "EventDetailView", bundle: nil).instantiate(withOwner: nil, options: nil)[0] as! EventDetailView
    }

    private func updateFonts() {
        recurringIcon?.textColor = UIColor.projectLightGray
        timeLabel?.textColor = UIColor.projectDarkGray
        locationLabel?.textColor = UIColor.projectDarkGray
        locationIconLabel?.textColor = UIColor.projectLightGray
        invitationSummaryLabel?.textColor = UIColor.projectLightGray
        detailLabel?.textColor = UIColor.projectDarkGray
    }

    func setup() {
        updateFonts()
        setupEventButtons()
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

    func responseType(forButton button: UIButton) -> EventResponse {
        if button == yesButton { return .yes }
        if button == noButton { return .no }
        if button == maybeButton { return .maybe }
        return .none
    }

    func setEventResponse(sender: UIButton) {
        let event = self.event!
        let response = self.responseType(forButton: sender)

        guard response != event.userResponse.value else {
            // selected button was tapped
            return
        }

        event.userResponse.update(to: response)
        event.temporarilyForceDisplayResponseOptions = true
        configure(with: event)

        try! event.flush()
    }

    @objc func remindMe() {
        event?.hackyCreateReminderFromEvent()
    }

    func updateActionButtons(forEvent event: EventSurface) {
        let isResponded = !event.needsResponse.value

        if isResponded {
            for button in [yesButton, noButton, maybeButton] as! [UIButton] {
                applyActionButtonFormat(to: button)
            }

            switch event.userResponse.value {
            case .yes:
                applyActionButtonFormat(to: yesButton,
                                        color: UIColor.white,
                                        backgroundColor: UIColor.projectBlue)
            case .no:
                applyActionButtonFormat(to: noButton,
                                        color: UIColor.white,
                                        backgroundColor: UIColor.projectRed)
            case .maybe:
                applyActionButtonFormat(to: maybeButton,
                                        color: UIColor.white,
                                        backgroundColor: UIColor.projectPurple)
            case .none:
                break;
            }
        } else {
            applyActionButtonFormat(to: yesButton, color: UIColor.projectBlue)
            applyActionButtonFormat(to: noButton, color: UIColor.projectRed)
            applyActionButtonFormat(to: maybeButton, color: UIColor.projectPurple)
        }

        applyActionButtonFormat(to: remindButton, bold: false)
    }

    func setupEventButtons() {
        for button in [yesButton, noButton, maybeButton] {
            button?.addTarget(self, action: #selector(setEventResponse), for: .touchUpInside)

            if  let button = button,
                let text = event?.buttonText(forResponse: self.responseType(forButton: button)) {
                button.setTitle(text, for: .normal)
                button.isHidden = false
            } else {
                button?.isHidden = true
            }
        }

        remindButton.addTarget(self, action: #selector(remindMe), for: .touchUpInside)
        locationButton.addTarget(self, action: #selector(launchMaps), for: .touchUpInside)
    }

    func applyActionButtonFormat(to button: UIButton,
                                 color: UIColor = UIColor.projectDarkGray,
                                 bold: Bool = true,
                                 backgroundColor: UIColor = UIColor.clear) {
        button.tintColor = color
        button.titleLabel?.font = button.titleLabel?.font.toSystemVersion(withBold: bold)
        button.backgroundColor = backgroundColor
        button.layer.cornerRadius = 5
        button.layer.masksToBounds = true
    }

    @objc private func launchMaps(sender: UIButton) {
        guard let title = sender.currentTitle else { return }
        guard let q = title.addingPercentEncoding(withAllowedCharacters: .urlHostAllowed) else { return }
        let googleString = "comgooglemaps://?q=\(q)"
        let appleString = "http://maps.apple.com/?q=\(q)"

        if let google = URL(string: googleString), UIApplication.shared.canOpenURL(google) {
            UIApplication.shared.open(google)
        }
        if let apple = URL(string: appleString), UIApplication.shared.canOpenURL(apple) {
            UIApplication.shared.open(apple)
        }
    }

}
