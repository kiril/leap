//
//  LocalCalendarViewController.swift
//  Leap
//
//  Created by Chris Ricca on 3/16/17.
//  Copyright © 2017 Kiril Savino. All rights reserved.
//

import Foundation
import UIKit
import EventKit

private let reuseIdentifier = "EventViewCell"

class CalendarCollectionViewController: UICollectionViewController, StoryboardLoadable {

    static var storyboardName: String {
        return "LocalCalendar"
    }

    let scheduleViewModel = CalendarCollectionViewController.mockedEntries()

    override func viewDidLoad() {
        super.viewDidLoad()

        setupCollectionView()
        setupNavigation()
    }

    private func setupCollectionView() {
        self.collectionView!.register(UINib(nibName: "EventViewCell", bundle: nil), forCellWithReuseIdentifier: reuseIdentifier)

        let layout = CalendarViewFlowLayout()

        self.collectionView!.collectionViewLayout = layout
        self.collectionView!.contentInset = UIEdgeInsets(top: 15.0, left: 15.0, bottom: 0.0, right: 15.0)
        self.collectionView!.alwaysBounceVertical = true
    }

    private func setupNavigation() {
        let titleNib = UINib(nibName: "DayScheduleTitleView", bundle: nil)
        let titleView = titleNib.instantiate(withOwner: nil, options: nil).first as! UIView

        let arrowNib = UINib(nibName: "NavigationToggleArrowView", bundle: nil)
        let arrowView = arrowNib.instantiate(withOwner: nil, options: nil).first as! UIView

        navigationItem.leftBarButtonItems = [
            barButtonItemFor(navView: arrowView),
            barButtonItemFor(navView: titleView)
        ]
    }

    private func barButtonItemFor(navView view: UIView) -> UIBarButtonItem {
        view.translatesAutoresizingMaskIntoConstraints = false
        let tap = UITapGestureRecognizer(target: self, action: #selector(didTapNavigation))
        view.addGestureRecognizer(tap)

        return UIBarButtonItem(customView: view)
    }

    @objc private func didTapNavigation() {
        let (navVC, _) = WeekOverviewViewController.loadFromStoryboardWithNavController()

        navVC.modalPresentationStyle = .overCurrentContext
        navVC.modalTransitionStyle = .crossDissolve

        present(navVC, animated: true, completion: nil)
    }

    // MARK: UICollectionViewDataSource

    override func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }

    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return scheduleViewModel.entries.value.count
    }

    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: reuseIdentifier, for: indexPath) as! EventViewCell
        self.configureCellWidth(cell)

        // Configure the cell

        let entry = scheduleViewModel.entries.value[indexPath.row]

        switch entry {
        case .event(let event):
            cell.configure(with: event)
        case .openTime:
            // for now, just hack in a new event view model since we don't have an open time view to display
            self.configureCellWidth(cell)
        }

        return cell
    }


    func configureCellWidth(_ cell: EventViewCell) {
        let targetWidth = collectionView!.bounds.size.width - 30
        cell.contentView.widthAnchor.constraint(equalToConstant: targetWidth).isActive = true
    }

    // MARK: UICollectionViewDelegate


}

extension CalendarCollectionViewController {
    static func mockedEntries() -> DayScheduleSurface {
        // mocking out entries

        var entries = [ScheduleEntry]()
        var tmpEvent: EventSurface!

        tmpEvent = EventSurface(mockData: [
            "time_range": "8 - 9am",
            "title": "Breakfast with John",
            "perspective": TimePerspective.past,
            "unresolved": false
        ])
        entries.append(ScheduleEntry.from(event: tmpEvent))

        tmpEvent = EventSurface(mockData: [
            "time_range": "10:30am - 12:30am",
            "title": "Important Meeting",
            "perspective": TimePerspective.current,
            "invitation_summary": "Eric Skiff ➝ You and 3 others",
            "unresolved": true,
            "elapsed": 0.67
        ])
        entries.append(ScheduleEntry.from(event: tmpEvent))

        tmpEvent = EventSurface(mockData: [
            "time_range": "3 - 4:30pm",
            "title": "Afternoon Meeting with a very long title this is a long title how big is it?! SO BIG",
            "perspective": TimePerspective.future,
            "unresolved": false
        ])
        entries.append(ScheduleEntry.from(event: tmpEvent))


        tmpEvent = EventSurface(mockData: [
            "time_range": "7 - 11:30pm",
            "title": "PARTY TIME 🎉",
            "perspective": TimePerspective.future,
            "invitation_summary": "Elizabeth Ricca ➝ You and 23 others",
            "unresolved": true
        ])
        entries.append(ScheduleEntry.from(event: tmpEvent))


        return DayScheduleSurface(mockData: ["entries": entries])
    }
}

extension CalendarCollectionViewController: UICollectionViewDelegateFlowLayout {
//    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
//        return UIEdgeInsets(top: 0.0, left: 15.0, bottom: 0.0, right: 15.0)
//    }
}
