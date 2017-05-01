//
//  EventViewCell.swift
//  Leap
//
//  Created by Chris Ricca on 3/16/17.
//  Copyright © 2017 Kiril Savino. All rights reserved.
//

import UIKit

protocol EventViewCellDelegate: class {
    func tapReceived(on: EventViewCell, for event: EventSurface)
    func fixConflictTapped(on: EventViewCell, for event: EventSurface)
}

class EventViewCell: UICollectionViewCell {
    @IBOutlet weak var topBorderView: UIView!

    // header
    @IBOutlet weak var timeWarningLabel: UILabel!
    @IBOutlet weak var timeLabel: UILabel!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var recurringIcon: UILabel!
    @IBOutlet weak var resolveButton: UIButton!
    @IBOutlet weak var arrivalDepartureLabel: UILabel!

    // detail
    @IBOutlet weak var invitationSummaryLabel: UILabel!
    @IBOutlet weak var invitationActionContainer: UIStackView!

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

    weak var delegate: EventViewCellDelegate?

    var borderColor: UIColor = UIColor.black {
        didSet { updateBorderColor() }
    }

    var displayShadow: Bool = false {
        didSet { updateShadow() }
    }

    private var event: EventSurface? {
        didSet {
            event?.register(observer: self)
            setupButtons()
        }
    }

    private func updateBorderColor() {
        self.backgroundColor = borderColor
        //self.layer.borderColor = borderColor.cgColor
        //self.layer.borderWidth = 1.0
    }

    private func updateShadow() {
        let shadowPath = UIBezierPath(rect: bounds)
        layer.masksToBounds = false;
        layer.shadowColor = UIColor.black.cgColor
        layer.shadowOffset = CGSize(width: 2, height: 2)
        layer.shadowPath = shadowPath.cgPath
        layer.shadowOpacity = displayShadow ? 0.1 : 0
        layer.shadowRadius = 2
    }

    private func setup() {
        updateBorderColor()
        updateShadow()
        updateFonts()
        setupButtons()

        self.contentView.translatesAutoresizingMaskIntoConstraints = false
        self.translatesAutoresizingMaskIntoConstraints = false
    }

    private func updateFonts() {
        invitationSummaryLabel.textColor = UIColor.projectLightGray
        locationIconLabel.textColor = UIColor.projectLightGray
        locationLabel.textColor = UIColor.projectLightGray
        recurringIcon.textColor = UIColor.projectLightGray
        arrivalDepartureLabel.textColor = UIColor.projectWarning

        timeWarningLabel.textColor = UIColor.orange
        titleLabel.textColor = UIColor.projectDarkGray
        timeLabel.textColor = UIColor.projectDarkGray

        topBorderView.backgroundColor = UIColor.projectWarning
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

    private func setupButtons() {
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
        resolveButton.addTarget(self, action: #selector(resolveConflict), for: .touchUpInside)
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        if let event = event, let touches = event.allTouches, touches.count == 1 {
            if let delegate = self.delegate {
                delegate.tapReceived(on: self, for: self.event!)
            }
        }
    }

    @objc private func remindMe() {
        event?.hackyCreateReminderFromEvent()
    }

    private func responseType(forButton button: UIButton) -> EventResponse {
        if button == yesButton { return .yes }
        if button == noButton { return .no }
        if button == maybeButton { return .maybe }
        return .none
    }

    @objc private func resolveConflict(sender: UIButton) {
        if let delegate = self.delegate {
            delegate.fixConflictTapped(on: self, for: event!)
        }
    }

    @objc private func setEventResponse(sender: UIButton) {
        let event = self.event!
        let response = self.responseType(forButton: sender)

        guard response != event.userResponse.value else { return }

        event.respond(with: response, forceDisplay: true)
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

    private func configure(location: String?) {
        if let location = location, !location.isEmpty {
            locationContainer.isHidden = false
            if location.looksLikeAnAddress {
                locationButton.isHidden = false
                locationLabel.isHidden = true
                locationButton.setTitle(location, for: .normal)
            } else {
                locationButton.isHidden = true
                locationLabel.isHidden = false
                locationLabel.text = location
            }
        } else {
            locationContainer.isHidden = true
        }
    }

    func configure(with event: EventSurface) {
        // move out of here to seperate helper classes
        // if this needs to be different
        // for different contexts

        // set values
        self.event = event

        timeLabel.text = event.timeRange.value
        titleLabel.text = event.title.value
        invitationSummaryLabel.text = event.invitationSummary.value
        timeWarningLabel.isHidden = !event.isInConflict
        resolveButton.isHidden = !event.isInConflict

        if !event.isInConflict && (event.hasCustomArrival || event.hasCustomDeparture) {
            var custom = ""
            if event.hasCustomArrival {
                let arrival = event.arrivalTime.value
                custom = "Arrive at \(DateFormatter.shortTime(date: arrival, appendAMPM: false))"
            }
            if event.hasCustomDeparture {
                let departure = event.departureTime.value
                if !custom.isEmpty {
                    custom += "; "
                }
                custom += "Leave by \(DateFormatter.shortTime(date: departure, appendAMPM: false))"
            }
            arrivalDepartureLabel.text = custom
            arrivalDepartureLabel.isHidden = false
            topBorderView.isHidden = false
        } else {
            arrivalDepartureLabel.isHidden = true
            topBorderView.isHidden = true
        }

        configure(location: event.locationSummary.rawValue)

        if event.isConfirmed.value {
            backgroundColor = UIColor.white
            borderColor = UIColor.projectLightGray
            displayShadow = false
        } else {
            backgroundColor = UIColor.projectLightBackgroundGray
            borderColor = UIColor.projectLightGray
            displayShadow = true
        }

        if event.perspective.value == .past {
            contentView.alpha = 0.8
            borderColor = UIColor.projectLightGray
        } else {
            contentView.alpha = 1.0
        }

        invitationActionContainer.isHidden = event.isConfirmed.value && !event.temporarilyForceDisplayResponseOptions

        recurringIcon.isHidden = !event.isRecurring.value

        updateActionButtons(forEvent: event)
    }

    private func updateActionButtons(forEvent event: EventSurface) {
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

    private func applyActionButtonFormat(to button: UIButton,
                                            color: UIColor = UIColor.projectDarkGray,
                                            bold: Bool = true,
                                            backgroundColor: UIColor = UIColor.clear) {
        button.tintColor = color
        button.titleLabel?.font = button.titleLabel?.font.toSystemVersion(withBold: bold)
        button.backgroundColor = backgroundColor
        button.layer.cornerRadius = 5
        button.layer.masksToBounds = true
    }


    override func layoutSubviews() {
        super.layoutSubviews()

        updateShadow()
    }
}

extension EventViewCell: SurfaceObserver {
    func surfaceDidChange(_ surface: Surface) {
        guard let event = surface as? EventSurface else { return }
        self.configure(with: event)
    }

    var sourceId: String { return "EventViewCell" }
}
