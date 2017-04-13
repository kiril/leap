//
//  EventViewCell.swift
//  Leap
//
//  Created by Chris Ricca on 3/16/17.
//  Copyright © 2017 Kiril Savino. All rights reserved.
//

import UIKit

protocol EventViewCellDelegate: class {
    func didChoose(response: InvitationResponse,
                   ignored: Bool,
                   forEventId eventId: String,
                   on eventViewCell: EventViewCell)
}

class EventViewCell: UICollectionViewCell {
    @IBOutlet weak var timeLabel: UILabel!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var invitationSummaryLabel: UILabel!
    @IBOutlet weak var invitationActionContainer: UIStackView!

    @IBOutlet weak var yesButton: UIButton!
    @IBOutlet weak var noButton: UIButton!
    @IBOutlet weak var maybeButton: UIButton!
    @IBOutlet weak var ignoreButton: UIButton!
    @IBOutlet weak var remindButton: UIButton!

    weak var delegate: EventViewCellDelegate?

    var borderColor: UIColor = UIColor.black {
        didSet { updateBorderColor() }
    }

    var displayShadow: Bool = false {
        didSet { updateShadow() }
    }

    private var event: EventSurface?

    private func updateBorderColor() {
        self.layer.borderColor = borderColor.cgColor
        self.layer.borderWidth = 1.0
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
    }

    private func updateFonts() {
        invitationSummaryLabel.textColor = UIColor.projectLightGray
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
        for button in [yesButton, noButton, maybeButton, ignoreButton] {
            button?.addTarget(self, action: #selector(setInvitationResponse), for: .touchUpInside)
        }
    }

    @objc private func setInvitationResponse(sender: UIButton) {
        let event = self.event!
        var response: InvitationResponse?
        var ignored: Bool?

        if sender == yesButton { response = .yes }
        if sender == noButton { response = .no }
        if sender == maybeButton { response = .maybe }

        if  let r = response {
            // yes, no, or maybe was tapped

            if r == event.userInvitationResponse.value {
                // selected response button was tapped, so force .none
                response = .none
            }
        } else {
            // ignore button was tapped
            ignored = !event.userIgnored.value
        }

        delegate?.didChoose(response: response ?? .none,
                            ignored: ignored ?? false,
                            forEventId: event.id,
                            on: self)
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

        if !event.userIsInvited.value || (event.userInvitationResponse.value == .yes) {
            backgroundColor = UIColor.white
            borderColor = UIColor.projectDarkGray
            displayShadow = false
        } else {
            backgroundColor = UIColor.projectLightBackgroundGray
            borderColor = UIColor.projectLightGray
            displayShadow = true
        }

        if event.perspective.value == .past {
            contentView.alpha = 0.5
            borderColor = UIColor.projectLightGray
        } else {
            contentView.alpha = 1.0
        }

        let showResponseActions = event.userIsInvited.value && (event.userInvitationResponse.value != .yes)
        invitationActionContainer.isHidden = !showResponseActions

        updateActionButtons(forEvent: event)
    }

    private func updateActionButtons(forEvent event: EventSurface) {
        let isResponded = event.userIgnored.value || (event.userInvitationResponse.value != .none)

        if isResponded {
            for button in [yesButton, noButton, maybeButton] as! [UIButton] {
                applyActionButtonFormat(to: button)
            }
            applyActionButtonFormat(to: ignoreButton, bold: false)

            if event.userIgnored.value {
                applyActionButtonFormat(to: ignoreButton,
                                        color: UIColor.white,
                                        bold: false,
                                        backgroundColor: UIColor.projectDarkGray)
            } else {
                switch event.userInvitationResponse.value {
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
                default:
                    break
                }
            }
        } else {
            applyActionButtonFormat(to: yesButton, color: UIColor.projectBlue)
            applyActionButtonFormat(to: noButton, color: UIColor.projectRed)
            applyActionButtonFormat(to: maybeButton, color: UIColor.projectPurple)
            applyActionButtonFormat(to: ignoreButton, bold: false)
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
