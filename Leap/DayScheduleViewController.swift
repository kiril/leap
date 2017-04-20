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

private let eventReuseIdentifier = "EventViewCell"
private let openTimeReuseIdentifier = "OpenTimeViewCell"

class DayScheduleViewController: UICollectionViewController, StoryboardLoadable {

    var surface: DayScheduleSurface!
    fileprivate lazy var prototypeEventCell: EventViewCell = {
        return Bundle.main.loadNibNamed("EventViewCell", owner: nil, options: nil)?.first as! EventViewCell
    }()

    fileprivate lazy var prototypeOpenTimeEventCell: OpenTimeViewCell = {
        return Bundle.main.loadNibNamed("OpenTimeViewCell", owner: nil, options: nil)?.first as! OpenTimeViewCell
    }()

    override func viewDidLoad() {
        super.viewDidLoad()

        setupCollectionView()
    }

    private func setupCollectionView() {
        self.collectionView!.register(UINib(nibName: "EventViewCell", bundle: nil), forCellWithReuseIdentifier: eventReuseIdentifier)
        self.collectionView!.register(UINib(nibName: "OpenTimeViewCell", bundle: nil), forCellWithReuseIdentifier: openTimeReuseIdentifier)

        let layout = CalendarViewFlowLayout()

        self.collectionView!.collectionViewLayout = layout
        self.collectionView!.contentInset = UIEdgeInsets(top:    15.0,
                                                         left:   15.0,
                                                         bottom: 75.0,
                                                         right:  15.0)
        self.collectionView!.alwaysBounceVertical = true
    }

    // MARK: UICollectionViewDataSource

    override func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }

    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return surface.numberOfEntries
    }

    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        var cell: UICollectionViewCell!

        // Configure the cell

        let entry = surface.entries[indexPath.row]

        switch entry {
        case .event(let event):
            cell = collectionView.dequeueReusableCell(withReuseIdentifier: eventReuseIdentifier, for: indexPath)
            (cell as! EventViewCell).configure(with: event)

        case .openTime(let openTime):
            cell = collectionView.dequeueReusableCell(withReuseIdentifier: openTimeReuseIdentifier, for: indexPath)
            (cell as! OpenTimeViewCell).configure(with: openTime)
        }

        self.configureCellWidth(cell)

        return cell
    }


    func configureCellWidth(_ cell: UICollectionViewCell) {
        cell.contentView.widthAnchor.constraint(equalToConstant: targetCellWidth).isActive = true
    }



    fileprivate var targetCellWidth: CGFloat {
        return collectionView!.bounds.size.width - 30
    }

    // MARK: UICollectionViewDelegate


}

extension DayScheduleViewController {
    static func mockedEntriesFor(dayId: String) -> DayScheduleSurface {
        // mocking out entries

        let events = [
            EventSurface(mockData: ["timeRange": "8 - 9am",
                                    "title": "Breakfast with John",
                                    "perspective": TimePerspective.past,
                                    "unresolved": false
                ]),
            EventSurface(mockData: ["timeRange": "10:30am - 12:30am",
                                    "title": "Important Meeting",
                                    "perspective": TimePerspective.current,
                                    "invitation_summary": "Eric Skiff ➝ You and 3 others",
                                    "unresolved": true,
                                    "elapsed": 0.67
                ]),
            EventSurface(mockData: ["timeRange": "3 - 4:30pm",
                                    "title": "Afternoon Meeting with a very long title this is a long title how big is it?! SO BIG",
                                    "perspective": TimePerspective.future,
                                    "unresolved": false
                ]),
            EventSurface(mockData: ["timeRange": "7 - 11:30pm",
                                    "title": "PARTY TIME 🎉",
                                    "perspective": TimePerspective.future,
                                    "invitation_summary": "Elizabeth Ricca ➝ You and 23 others",
                                    "unresolved": true
                ])
        ]

        return DayScheduleSurface(mockData: ["events": events], id: dayId)
    }
}

extension DayScheduleViewController: SourceIdentifiable {
    var sourceId: String { return "DayScheduleVC" }
}


extension DayScheduleViewController: SurfaceObserver {
    func surfaceDidChange(_ surface: Surface) {
        self.collectionView?.reloadData()
        self.collectionView?.collectionViewLayout.invalidateLayout()
    }
}

extension DayScheduleViewController: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView,
                        layout collectionViewLayout: UICollectionViewLayout,
                        sizeForItemAt indexPath: IndexPath) -> CGSize {

        let entry = surface.entries[indexPath.row]

        let targetSize = CGSize(width: targetCellWidth, height: 100000000)

        switch entry {
        case .event(let event):
            configureCellWidth(prototypeEventCell)
            prototypeEventCell.configure(with: event)
            let size = prototypeEventCell.systemLayoutSizeFitting(targetSize)
            return size

        case .openTime(let openTime):
            configureCellWidth(prototypeOpenTimeEventCell)
            prototypeOpenTimeEventCell.configure(with: openTime)
            let size = prototypeOpenTimeEventCell.systemLayoutSizeFitting(targetSize)
            return size
        }
    }
}
