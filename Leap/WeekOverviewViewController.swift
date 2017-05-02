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

    var surface: WeekOverviewSurface? {
        didSet {
            surface?.register(observer: self)
            surface?.loadWeekBusyness()
        }
    }

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
        }
        updateBusyness()
        updateSelected()
    }

    fileprivate func updateBusyness() {
        for (index, dayView) in dayListingViews.enumerated() {
            guard let busyness = surface?.weekBusyness[index] else { continue }

            dayView.daytimeBusynessIndicator.topCircleComplete = busyness.committedDaytime
            dayView.daytimeBusynessIndicator.bottomCircleComplete = busyness.unresolvedDaytime
            dayView.eveningBusynessIndicator.topCircleComplete = busyness.committedEvening
            dayView.eveningBusynessIndicator.bottomCircleComplete = busyness.unresolvedEvening
        }
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

extension WeekOverviewViewController: SurfaceObserver {
    var sourceId: String { return "WeekOverviewViewController" }

    func surfaceDidChange(_ surface: Surface) {
        self.updateBusyness()
    }
}
