//
//  EventDetailView.swift
//  Leap
//
//  Created by Kiril Savino on 4/27/17.
//  Copyright © 2017 Single Leap, Inc. All rights reserved.
//

import UIKit

protocol EventDetailViewDelegate: class {
    func eventTapped(with event: EventSurface)
    func didChangeResponse(for event: EventSurface)
}

class EventDetailView: UIView {
    var event: EventSurface?
    var nextEvent: EventSurface?
    var priorEvent: EventSurface?
    weak var delegate: EventDetailViewDelegate?

    // container
    @IBOutlet weak var stackView: UIStackView!

    // header
    @IBOutlet weak var timeLabel: UILabel!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var recurringIcon: UILabel!
    @IBOutlet weak var timeAlertLabel: UILabel!
    @IBOutlet weak var conflictLabel: UILabel!

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
    @IBOutlet weak var beforeAlertIcon: UILabel!
    @IBOutlet weak var afterAlertIcon: UILabel!
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
        timeAlertLabel.isHidden = !event.isInConflict

        if event.isInConflict {
            var conflicts: [EventSurface] = []
            for entry in entries {
                switch entry {
                case let .event(other):
                    if other.intersectsWith(event) && other != event {
                        conflicts.append(other)
                    }
                default:
                    continue
                }
            }
            var conflictText = ""
            for conflictingEvent in conflicts {
                if !conflictText.isEmpty {
                    conflictText += "; "
                }
                let eventDescription = "\(conflictingEvent.title.value) at \(DateFormatter.shortTime(date: conflictingEvent.startTime.value))"
                conflictText += eventDescription
            }
            conflictText = "Conflicts with: \(conflictText)"
            conflictLabel.text = conflictText
            conflictLabel.isHidden = false

        } else {
            conflictLabel.isHidden = true
        }

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

        detailLabel.text = event.detail.value
        if !detailLabel.text!.hasNonWhitespaceCharacters {
            detailLabel.isHidden = true
            detailSeparator.isHidden = true
        } else {
            detailLabel.isHidden = false
            detailSeparator.isHidden = false
        }

        configureBeforeAndAfter()
        configureAlerts()
        configureAttendees()
    }

    func configureAttendees() {
        for participant in event!.participants.value {
            guard !participant.isMe.value else { continue }
            let name = UILabel()
            name.textColor = UIColor.projectDarkGray
            name.text = participant.name.value
            name.font = UIFont.systemFont(ofSize: 15)

            let response = UILabel()
            response.text = {
                switch participant.engagement.value {
                case .engaged:
                    return "Attending"
                case .disengaged:
                    return "Declined"
                case Engagement.tracking:
                    return "Maybe"
                default:
                    return "No Response"
                }
            }()
            response.textColor = {
                switch participant.engagement.value {
                case .engaged:
                    return UIColor.projectBlue
                case .disengaged:
                    return UIColor.projectRed
                case Engagement.tracking:
                    return UIColor.projectPurple
                default:
                    return UIColor.projectLightGray
                }
            }()
            response.textAlignment = NSTextAlignment.right
            response.font = UIFont.boldSystemFont(ofSize: 15)

            let stack = UIStackView()
            stack.axis = .horizontal
            stack.addArrangedSubview(name)
            stack.addArrangedSubview(response)
            stack.tag = 9000

            var i = 0
            for view in stackView.arrangedSubviews {
                if view == invitationSummaryLabel {
                    break
                }
                i += 1
            }

            stackView.insertArrangedSubview(stack, at: i+1)
        }
    }

    @objc func afterButtonTapped(sender: UIButton) {
        if let delegate = self.delegate, let event = nextEvent {
            delegate.eventTapped(with: event)
        }
    }

    @objc func beforeButtonTapped(sender: UIButton) {
        if let delegate = self.delegate, let event = priorEvent {
            delegate.eventTapped(with: event)
        }
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

        beforeAlertIcon.isHidden = true
        afterAlertIcon.isHidden = true

        if let event = priorEvent, let open = priorOpen {
            let beforeString = "\(event.title.value) ends \(open.durationSeconds.durationString) before this at \(DateFormatter.shortTime(date: event.endTime.value))"
            let beforeText = NSMutableAttributedString(string: beforeString)
            beforeText.addAttribute(NSForegroundColorAttributeName, value: UIColor.projectTint, range: NSRange(location: 0, length: event.title.value.utf16.count))

            let lengthOfTitle = event.title.value.utf16.count
            let postTitleRange = NSRange(location: lengthOfTitle, length: beforeString.utf16.count - lengthOfTitle)
            beforeText.addAttribute(NSForegroundColorAttributeName, value: UIColor.projectDarkGray, range: postTitleRange)

            beforeButton.setAttributedTitle(beforeText, for: .normal)

            beforeLabel.isHidden = true
            beforeButton.isHidden = false

        } else if let event = priorEvent {
            let beforeString = "This event immediately follows \(event.title.value)."
            let beforeText = NSMutableAttributedString(string: beforeString)
            let lengthOfTitle = event.title.value.utf16.count
            let titleRange = NSRange(location: beforeString.utf16.count - lengthOfTitle - 1, length: lengthOfTitle)
            beforeText.addAttribute(NSForegroundColorAttributeName, value: UIColor.projectTint, range: titleRange)
            let preTitleRange = NSRange(location: 0, length: beforeString.utf16.count - lengthOfTitle - 1)
            beforeText.addAttribute(NSForegroundColorAttributeName, value: UIColor.projectDarkGray, range: preTitleRange)
            let periodRange = NSRange(location: beforeString.utf16.count - 1, length: 1)
            beforeText.addAttribute(NSForegroundColorAttributeName, value: UIColor.projectDarkGray, range: periodRange)

            beforeButton.setAttributedTitle(beforeText, for: .normal)

            beforeLabel.isHidden = true
            beforeButton.isHidden = false
            beforeAlertIcon.isHidden = false

        } else {
            beforeLabel.text = "This is the first event of the day."
            beforeLabel.isHidden = false
            beforeButton.isHidden = true
        }

        if let event = afterEvent, let open = afterOpen {
            let afterString = "\(event.title.value) starts \(open.durationSeconds.durationString) after this at \(DateFormatter.shortTime(date: event.startTime.value))."
            let afterText = NSMutableAttributedString(string: afterString)
            afterText.addAttribute(NSForegroundColorAttributeName, value: UIColor.projectTint, range: NSRange(location: 0, length: event.title.value.utf16.count))
            let lengthOfTitle = event.title.value.utf16.count
            let postTitleRange = NSRange(location: lengthOfTitle, length: afterString.utf16.count - lengthOfTitle)
            afterText.addAttribute(NSForegroundColorAttributeName, value: UIColor.projectDarkGray, range: postTitleRange)
            afterButton.setAttributedTitle(afterText, for: .normal)
            afterLabel.isHidden = true
            afterButton.isHidden = false

        } else if let event = afterEvent {
            let afterString = "Followed immediately by \(event.title.value)"
            let afterText = NSMutableAttributedString(string: afterString)
            let lengthOfTitle = event.title.value.utf16.count
            let titleRange = NSRange(location: afterString.utf16.count - lengthOfTitle - 1, length: lengthOfTitle)
            afterText.addAttribute(NSForegroundColorAttributeName, value: UIColor.projectTint, range: titleRange)
            let preTitleRange = NSRange(location: 0, length: afterString.utf16.count - lengthOfTitle)
            afterText.addAttribute(NSForegroundColorAttributeName, value: UIColor.projectDarkGray, range: preTitleRange)
            let periodRange = NSRange(location: afterString.utf16.count - 1, length: 1)
            afterText.addAttribute(NSForegroundColorAttributeName, value: UIColor.projectDarkGray, range: periodRange)

            afterButton.setAttributedTitle(afterText, for: .normal)

            afterLabel.isHidden = true
            afterButton.isHidden = false
            afterAlertIcon.isHidden = false

        } else {
            afterLabel.text = "This is the last event of the day."
            afterButton.isHidden = true
            afterLabel.isHidden = false
        }
    }

    class func instanceFromNib() -> EventDetailView {
        return UINib(nibName: "EventDetailView", bundle: nil).instantiate(withOwner: nil, options: nil)[0] as! EventDetailView
    }

    private func updateStyle() {
        recurringIcon?.textColor = UIColor.projectLightGray
        timeLabel?.textColor = UIColor.projectDarkGray
        locationLabel?.textColor = UIColor.projectDarkGray
        locationIconLabel?.textColor = UIColor.projectLightGray
        invitationSummaryLabel?.textColor = UIColor.projectLightGray
        detailLabel?.textColor = UIColor.projectDarkGray
        timeAlertLabel.textColor = UIColor.projectWarning

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
        beforeAlertIcon.textColor = UIColor.projectWarning
        afterAlertIcon.textColor = UIColor.projectWarning
        timeLabel.textColor = UIColor.projectLightGray
        conflictLabel.textColor = UIColor.projectWarning
    }

    func setup() {
        updateStyle()
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

        if let delegate = self.delegate {
            delegate.didChangeResponse(for: event)
        }
    }

    @objc func remindMe() {
        event?.hackyCreateReminderFromEvent()

        if let delegate = self.delegate {
            delegate.didChangeResponse(for: event!)
        }
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
        afterButton.addTarget(self, action: #selector(afterButtonTapped), for: .touchUpInside)
        beforeButton.addTarget(self, action: #selector(beforeButtonTapped), for: .touchUpInside)
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
