//
//  EventViewCell.swift
//  Leap
//
//  Created by Chris Ricca on 3/16/17.
//  Copyright © 2017 Kiril Savino. All rights reserved.
//

import UIKit

protocol EventViewCellDelegate: class {
    func tapReceived(on cell: EventViewCell, for event: EventSurface)
    func fixConflictTapped(on cell: EventViewCell, for event: EventSurface)
    func selectedNewEventResponse(_ response: EventResponse, on cell: EventViewCell, for event: EventSurface)
    func updatedTimePerspective(on cell: EventViewCell, for event: EventSurface)
}

class EventViewCell: UICollectionViewCell {

    // elapsed time
    @IBOutlet weak var elapsedTimeIndicatorView: TimeProgressView!
    @IBOutlet weak var elapsedTimeHeightConstraint: NSLayoutConstraint!

    // time info
    @IBOutlet weak var background: UIView!
    @IBOutlet weak var subscribedIcon: UILabel!
    @IBOutlet weak var timeWarningLabel: UILabel!
    @IBOutlet weak var timeLabel: UILabel!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var resolveButton: UIButton!

    // detail
    @IBOutlet weak var invitationSummaryLabel: UILabel!
    @IBOutlet weak var invitationActionContainer: UIStackView!

    // icons!!
    @IBOutlet weak var recurringIcon: UILabel!
    @IBOutlet weak var facebookIcon: UILabel!
    @IBOutlet weak var slackIcon: UILabel!
    @IBOutlet weak var videoIcon: UILabel!
    @IBOutlet weak var ticketIcon: UILabel!
    @IBOutlet weak var phoneIcon: UILabel!
    @IBOutlet weak var skypeIcon: UILabel!
    @IBOutlet weak var photoIcon: UILabel!
    @IBOutlet weak var shareIcon: UILabel!
    @IBOutlet weak var fileIcon: UILabel!
    @IBOutlet weak var commentIcon: UILabel!
    @IBOutlet weak var checklistIcon: UILabel!
    @IBOutlet weak var alarmIcon: UILabel!
    @IBOutlet weak var descriptionIcon: UILabel!
    @IBOutlet weak var brokenLinkIcon: UILabel!

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

    var timePerspectiveUpdatesEnabled = true {
        didSet { setupCurrentEventUpdates() }
    }

    var borderColor: UIColor = UIColor.black {
        didSet { updateBorderColor() }
    }

    var displayShadow: Bool = false {
        didSet { updateShadow() }
    }

    fileprivate var event: EventSurface? {
        didSet {
            event?.register(observer: self)
            setupButtons()
        }
    }

    var day: GregorianDay?

    private func updateBorderColor() {
        background.layer.borderColor = borderColor.cgColor
        background.layer.borderWidth = 1.0
    }


    private let cornerRadius: CGFloat = 3.0

    private func updateShadow() {
        let shadowPath = UIBezierPath(rect: bounds)
        layer.masksToBounds = false;
        layer.shadowColor = UIColor.black.cgColor
        layer.shadowOffset = CGSize(width: 2, height: 2)
        layer.shadowPath = shadowPath.cgPath
        layer.shadowOpacity = displayShadow ? 0.1 : 0
        layer.shadowRadius = 2
        layer.cornerRadius = cornerRadius
    }

    private func setupCorners() {
        background.layer.cornerRadius = cornerRadius
        background.layer.masksToBounds = true
    }

    var elapsedTimeIndicatorHidden = true {
        didSet { updateElapsedTimeIndicator() }
    }

    var elapsedTimePercent: CGFloat = 0.0 {
        didSet { updateElapsedTimeIndicator() }
    }

    private func updateElapsedTimeIndicator() {
        elapsedTimeIndicatorView.isHidden = elapsedTimeIndicatorHidden
        elapsedTimeHeightConstraint.constant = elapsedTimeIndicatorHidden ? 0.0 : 7.0



        elapsedTimeIndicatorView.setProgress(progress: self.elapsedTimePercent,
                                             withEdgeBuffer: 0.02)

    }

    private func setup() {
        updateBorderColor()
        updateShadow()
        updateFonts()
        setupButtons()
        setupCorners()
        updateElapsedTimeIndicator()

        self.contentView.translatesAutoresizingMaskIntoConstraints = false
        self.translatesAutoresizingMaskIntoConstraints = false
    }

    private func updateFonts() {
        invitationSummaryLabel.textColor = UIColor.projectLightGray
        locationLabel.textColor = UIColor.projectLightGray
        recurringIcon.textColor = UIColor.projectLightGray
        descriptionIcon.textColor = UIColor.projectLightGray

        for icon:UILabel in [alarmIcon, recurringIcon, checklistIcon, commentIcon, locationIconLabel, fileIcon, shareIcon, brokenLinkIcon, phoneIcon, skypeIcon, ticketIcon, videoIcon, photoIcon, facebookIcon, slackIcon] {
            icon.textColor = UIColor.projectLightGray
        }

        timeWarningLabel.textColor = UIColor.orange
        titleLabel.textColor = UIColor.projectDarkGray
        timeLabel.textColor = UIColor.projectDarkGray
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
        event?.hackyShowAsReminder()
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

        if let delegate = self.delegate {
            delegate.selectedNewEventResponse(response, on: self, for: event)
        }
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

    func configureOrigin(with event: EventSurface) {

        shareIcon.isHidden = true
        subscribedIcon.isHidden = true

        switch event.origin.value {
        case .invite:
            break

        case .share:
            // I don't know what to use here, if anything: I have an 'eye' right now, which sucks.
            //shareIcon.isHidden = false
            break

        case .subscription:
            subscribedIcon.isHidden = false

        case .personal:
            break
            
        case .unknown:
            break
        }
    }

    func configure(with event: EventSurface, on day: GregorianDay) {
        self.day = day
        self.event = event

        configureOrigin(with: event)

        timeLabel.attributedText = event.formatAttendance(viewedFrom: day)

        titleLabel.text = event.title.value
        invitationSummaryLabel.text = event.invitationSummary.value

        timeWarningLabel.isVisible = event.isInConflict && !event.temporarilyForceDisplayResponseOptions
        resolveButton.isVisible = event.isInConflict && !(event.needsResponse.value || event.temporarilyForceDisplayResponseOptions)
        invitationActionContainer.isVisible = !event.isConfirmed.value || event.temporarilyForceDisplayResponseOptions

        configure(location: event.locationSummary.rawValue)
        configureTimePerspective(with: event)
        configureIcons(with: event)
        updateActionButtons(forEvent: event)
        setupCurrentEventUpdates()
    }

    fileprivate func configureTimePerspective(with event: EventSurface) {
        background.backgroundColor = UIColor.white
        borderColor = UIColor.projectLightGray

        if event.isConfirmed.value {
            displayShadow = true
        } else {
            displayShadow = false
        }


        switch event.perspective.value {
        case .past:
            borderColor = UIColor.projectLightGray
            elapsedTimeIndicatorHidden = true
        case .current:
            elapsedTimeIndicatorHidden = false
            elapsedTimePercent = CGFloat(event.percentElapsed.value)
        case .future:
            elapsedTimeIndicatorHidden = true
        }

        switch event.userAttendancePerspective.value {
        case .past:
            contentView.alpha = 0.5
            displayShadow = false
            elapsedTimeIndicatorView.progressColor = UIColor.projectLightGray

        case .current:
            contentView.alpha = 1.0
            if event.isConfirmed.value {
                elapsedTimeIndicatorView.progressColor = UIColor.projectBlue

                borderColor = UIColor.projectBlue
            } else {
                elapsedTimeIndicatorView.progressColor = UIColor.projectLightGray
            }
        case .future:
            contentView.alpha = 1.0
            elapsedTimeIndicatorView.progressColor = UIColor.projectLightGray
        }

    }

    private func configureIcons(with event: EventSurface) {
        recurringIcon.isVisible = event.isRecurring.value
        descriptionIcon.isVisible = event.hasDetail
        alarmIcon.isVisible = event.hasAlarms.value
        checklistIcon.isVisible = event.hasAgenda
        brokenLinkIcon.isVisible = event.isDetached
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
                                        backgroundColor: UIColor.projectDarkGray)
            case .maybe:
                applyActionButtonFormat(to: maybeButton,
                                        color: UIColor.white,
                                        backgroundColor: UIColor.projectPurple)
            case .none:
                break;
            }
        } else {
            applyActionButtonFormat(to: yesButton, color: UIColor.projectBlue)
            applyActionButtonFormat(to: noButton, color: UIColor.projectDarkGray)
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

    private var timeObserver: TimeRangeObserver?

    private func setupCurrentEventUpdates() {
        guard   let event = event,
                let range = event.eventRange else { return }

        guard timePerspectiveUpdatesEnabled else {
            timeObserver = nil
            return
        }

        timeObserver = TimeRangeObserver(range: range)
        timeObserver?.delegate = self
    }
}

extension EventViewCell: TimeRangeObserverDelegate {
    func didObserveTimePerspectiveChange(on observer: TimeRangeObserver) {
        guard let event = event else { return }
        self.delegate?.updatedTimePerspective(on: self, for: event)
    }

    func didObserveMinuteChangeWhenCurrent(on observer: TimeRangeObserver) {
        guard let event = event else { return }
        UIView.animate(withDuration: 0.2) { [weak self] in
            self?.configureTimePerspective(with: event)
            self?.setNeedsLayout()
            self?.layoutIfNeeded()
        }
    }
}

extension EventViewCell: SurfaceObserver {
    func surfaceDidChange(_ surface: Surface) {
        guard let event = surface as? EventSurface else { return }
        self.configure(with: event, on: day!)
    }

    var sourceId: String { return "EventViewCell" }
}
