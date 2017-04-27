//
//  EventDetailView.swift
//  Leap
//
//  Created by Kiril Savino on 4/27/17.
//  Copyright © 2017 Single Leap, Inc. All rights reserved.
//

import UIKit

class EventDetailView: UIView, EventInterface {
    @IBOutlet weak var recurringIcon: UILabel!
    @IBOutlet weak var timeLabel: UILabel!

    @IBOutlet weak var remindButton: UIButton!
    @IBOutlet weak var maybeButton: UIButton!
    @IBOutlet weak var noButton: UIButton!
    @IBOutlet weak var yesButton: UIButton!
    
    var event: EventSurface?

    func configure(with event: EventSurface) {
        self.event = event
        print("configureWithEvent")
        recurringIcon.isHidden = !event.isRecurring.value
        timeLabel.text = event.timeRange.value

        updateActionButtons(forEvent: event)
        setup()
    }

    private func updateFonts() {
        recurringIcon.textColor = UIColor.projectLightGray
        timeLabel.textColor = UIColor.projectLightGray
    }

    func setup() {
        updateFonts()
        setupEventButtons()
    }

    @objc private func setEventResponse_objc(sender: UIButton) {
        setEventResponse(sender: sender)
    }

    @objc private func remindMe_objc(sender: UIButton) {
        remindMe()
    }

    func setRemindTarget(for button: UIButton?) {
        button?.addTarget(self, action: #selector(remindMe_objc), for: .touchUpInside)
    }

    func setResponseTarget(for button: UIButton?) {
        button?.addTarget(self, action: #selector(setEventResponse_objc), for: .touchUpInside)
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

    class func instanceFromNib() -> EventDetailView {
        return UINib(nibName: "EventDetailView", bundle: nil).instantiate(withOwner: nil, options: nil)[0] as! EventDetailView
    }
}
