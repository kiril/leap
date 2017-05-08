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
    // cell bits
    @IBOutlet weak var raggedEdgeView: RaggedEdgeView!
    @IBOutlet weak var raggedEdgeHeight: NSLayoutConstraint!
    @IBOutlet weak var bottomRaggedEdgeView: RaggedEdgeView!
    @IBOutlet weak var bottomRaggedEdgeHeight: NSLayoutConstraint!

    // elapsed time
    @IBOutlet weak var elapsedTimeIndicatorView: UIView!
    @IBOutlet weak var elapsedTimeHeightConstraint: NSLayoutConstraint!
    private weak var elapsedTimeWidthConstraint: NSLayoutConstraint?

    // time info
    @IBOutlet weak var background: UIView!
    @IBOutlet weak var subscribedIcon: UILabel!
    @IBOutlet weak var timeWarningLabel: UILabel!
    @IBOutlet weak var timeLabel: UILabel!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var resolveButton: UIButton!
    @IBOutlet weak var arrivalDepartureLabel: UILabel!

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

    var day: GregorianDay?

    private func updateBorderColor() {
        background.layer.borderColor = borderColor.cgColor
        background.layer.borderWidth = 1.0
        raggedEdgeView.lineColor = borderColor
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

    var elapsedTimeIndicatorHidden = true {
        didSet { updateElapsedTimeIndicator() }
    }

    var elapsedTimePercent: CGFloat = 0.0 {
        didSet { updateElapsedTimeIndicator() }
    }

    private func updateElapsedTimeIndicator() {
        elapsedTimeIndicatorView.isHidden = elapsedTimeIndicatorHidden
        elapsedTimeHeightConstraint.constant = elapsedTimeIndicatorHidden ? 0.0 : 7.0
        elapsedTimeWidthConstraint?.isActive = false

        let elapsedTimePercent = max(0.0, min(1.0, self.elapsedTimePercent))
        elapsedTimeWidthConstraint = elapsedTimeIndicatorView.widthAnchor.constraint(equalTo: self.widthAnchor,
                                                                                     multiplier: elapsedTimePercent,
                                                                                     constant: 0)
        elapsedTimeWidthConstraint?.isActive = true
    }

    private func setup() {
        updateBorderColor()
        updateShadow()
        updateFonts()
        setupButtons()
        setupRaggedEdges()
        updateElapsedTimeIndicator()

        self.contentView.translatesAutoresizingMaskIntoConstraints = false
        self.translatesAutoresizingMaskIntoConstraints = false
    }

    private func setupRaggedEdges() {
        raggedEdgeView.orientation = .top
        raggedEdgeView.edgeDisposition = .innie
        bottomRaggedEdgeView.orientation = .bottom
        bottomRaggedEdgeView.edgeDisposition = .outie
    }

    private func updateFonts() {
        invitationSummaryLabel.textColor = UIColor.projectLightGray
        locationLabel.textColor = UIColor.projectLightGray
        recurringIcon.textColor = UIColor.projectLightGray
        descriptionIcon.textColor = UIColor.projectLightGray
        arrivalDepartureLabel.textColor = UIColor.projectWarning

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

    func configureArrivalDeparture(with event: EventSurface) {

        arrivalDepartureLabel.isVisible = false
        raggedEdgeView.isVisible = false
        raggedEdgeHeight.constant = 1
        bottomRaggedEdgeView.isVisible = false
        bottomRaggedEdgeHeight.constant = 1

        if !event.isInConflict && (event.hasCustomArrival || event.hasCustomDeparture) {
            let bold = [NSFontAttributeName: timeLabel.font!]
            let normal = [NSFontAttributeName: arrivalDepartureLabel.font!]

            let custom = NSMutableAttributedString()
            if event.hasCustomArrival {
                let arrival = event.arrivalTime.value
                let time = DateFormatter.shortTime(date: arrival, appendAMPM: true)
                custom.append(string: time, attributes: bold)
                custom.append(string: " arrival", attributes: normal)

                raggedEdgeHeight.constant = 11
                raggedEdgeView.isVisible = true
                raggedEdgeView.setNeedsDisplay()
            }

            if event.hasCustomDeparture {
                let departure = event.departureTime.value
                if custom.length > 0 {
                    custom.append(string: "; ", attributes: normal)
                }
                let time = DateFormatter.shortTime(date: departure, appendAMPM: true)
                custom.append(string: "depart ", attributes: normal)
                custom.append(string: time, attributes: bold)

                bottomRaggedEdgeHeight.constant = 11
                bottomRaggedEdgeView.isVisible = true
                bottomRaggedEdgeView.setNeedsDisplay()
            }

            arrivalDepartureLabel.attributedText = custom
            arrivalDepartureLabel.isVisible = true
        }
    }

    func configure(with event: EventSurface, on day: GregorianDay) {
        self.day = day
        self.event = event

        configureOrigin(with: event)
        configureArrivalDeparture(with: event)

        if let day = self.day {
            timeLabel.text = event.formatDuration(viewedFrom: day)
        } else {
            timeLabel.text = event.timeString.value
        }

        titleLabel.text = event.title.value
        invitationSummaryLabel.text = event.invitationSummary.value

        timeWarningLabel.isVisible = event.isInConflict && !event.temporarilyForceDisplayResponseOptions
        resolveButton.isVisible = event.isInConflict && !(event.needsResponse.value || event.temporarilyForceDisplayResponseOptions)
        invitationActionContainer.isVisible = !event.isConfirmed.value || event.temporarilyForceDisplayResponseOptions

        configure(location: event.locationSummary.rawValue)
        configureTimePerspective(with: event)
        configureIcons(with: event)
        updateActionButtons(forEvent: event)
        ensureCurrentEventUpdates()
    }

    private func configureTimePerspective(with event: EventSurface) {
        if event.isConfirmed.value {
            background.backgroundColor = UIColor.white
            raggedEdgeView.maskColor = UIColor.white
            borderColor = UIColor.projectLightGray
            displayShadow = false
        } else {
            background.backgroundColor = UIColor.projectLightBackgroundGray
            raggedEdgeView.maskColor = UIColor.projectLightBackgroundGray
            borderColor = UIColor.projectLightGray
            displayShadow = true
        }

        elapsedTimeIndicatorView.backgroundColor = UIColor.projectLightGray

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
        case .current:
            contentView.alpha = 1.0
            if event.isConfirmed.value {
                elapsedTimeIndicatorView.backgroundColor = UIColor.projectBlue
            }
        case .future:
            contentView.alpha = 1.0
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

    private var currentEventTimer: Timer?
    private var lastPerspective: TimePerspective!

    private func ensureCurrentEventUpdates() {
        // this should be called once per event configuration
        guard let   perspective = event?.perspective.value,
                    perspective != .past else {
                        cancelCurrentEventTimer()
                        return
        }

        lastPerspective = perspective

        setupCurrentDisplayTimer()
    }

    private func nextRoundMinute() -> Date {
        let calendar = Calendar.current
        let now = Date()
        var components = calendar.dateComponents([.era,.year,.month,.day,.hour,.minute], from: now)
        components.setValue(components.minute! + 1, for: .minute)
        return calendar.date(from: components)!
    }

    private func setupCurrentDisplayTimer() {
        guard currentEventTimer == nil else { return }

        currentEventTimer = Timer(fire: nextRoundMinute(), interval: 60, repeats: true) { [weak self] timer in
            guard   let _self = self,
                    let event = _self.event else {
                    timer.invalidate()
                    return
            }

            if _self.lastPerspective != event.perspective.value {
                _self.delegate?.updatedTimePerspective(on: _self,
                                                       for: event)
            } else if event.perspective.value == .current {

                UIView.animate(withDuration: 0.2) {
                    _self.configureTimePerspective(with: event)
                    _self.setNeedsLayout()
                    _self.layoutIfNeeded()
                }
            }

            _self.ensureCurrentEventUpdates()
        }

        let runLoop = RunLoop.current
        runLoop.add(currentEventTimer!, forMode: .defaultRunLoopMode)
    }

    private func cancelCurrentEventTimer() {
        currentEventTimer?.invalidate()
        currentEventTimer = nil
    }
}

extension EventViewCell: SurfaceObserver {
    func surfaceDidChange(_ surface: Surface) {
        guard let event = surface as? EventSurface else { return }
        self.configure(with: event, on: day!)
    }

    var sourceId: String { return "EventViewCell" }
}
