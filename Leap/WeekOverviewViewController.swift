//
//  WeekOverviewViewController.swift
//  Leap
//
//  Created by Chris Ricca on 4/1/17.
//  Copyright © 2017 Single Leap, Inc. All rights reserved.
//

import UIKit

protocol WeekOverviewViewControllerDelegate: class {
    func didSelectDay(dayId: String, on viewController: WeekOverviewViewController)
}

class WeekOverviewViewController: UIViewController, StoryboardLoadable {

    weak var delegate: WeekOverviewViewControllerDelegate?

    @IBOutlet var dayListingViews: [WeekOverviewDayListingView]!

    var surface: WeekOverviewSurface?

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        setupDays()
    }

    var selectedDayId: String? {
        didSet { updateSelected() }
    }

    private func setupDays() {
        for (index, dayView) in dayListingViews.enumerated() {
            guard let day = surface?.days[index] else { continue }
            guard let schedule = surface?.daySchedules[index] else { continue }

            dayView.isUserInteractionEnabled = true
            dayView.dayNameLabel.text = day.weekdayNameShort
            dayView.dayNumberLabel.text = day.dayOfTheMonth

            let tapGesture = UITapGestureRecognizer(target: self,
                                                    action: #selector(didTapButton(sender:)))
            dayView.addGestureRecognizer(tapGesture)


            switch day.happensIn {
            case .current:
                dayView.labelColor = UIColor.projectPurple
                dayView.isBold = true
            case .future:
                dayView.labelColor = UIColor.projectDarkerGray
            case .past:
                dayView.labelColor = UIColor.projectLightGray
            }

            dayView.daytimeBusynessIndicator.topCircleComplete = schedule.percentBooked(forType: .commited,
                                                                                        during: .day)
            dayView.daytimeBusynessIndicator.bottomCircleComplete = schedule.percentBooked(forType: .committedAndUnresolved,
                                                                                           during: .day)
            dayView.eveningBusynessIndicator.topCircleComplete = schedule.percentBooked(forType: .commited,
                                                                                        during: .evening)
            dayView.eveningBusynessIndicator.bottomCircleComplete = schedule.percentBooked(forType: .committedAndUnresolved,
                                                                                           during: .evening)
        }

        updateSelected()
    }

    private func updateSelected() {
        guard dayListingViews != nil else { return }
        for (index, dayView) in dayListingViews.enumerated() {
            guard let day = surface?.days[index] else { continue }
            dayView.isSelected = (day.id == selectedDayId)
        }
    }

    @objc func didTapButton(sender: UITapGestureRecognizer) {
        guard let tappedView = sender.view else { return }
        for (index, view) in dayListingViews.enumerated() {
            if tappedView == view {
                guard let id = surface?.days[index].id else { return }
                selectedDayId = id
                delegate?.didSelectDay(dayId: id, on: self)
                return
            }
        }
    }
}
