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
import IGListKit

class DayScheduleViewController: UIViewController, StoryboardLoadable {

    @IBOutlet weak var collectionView: IGListCollectionView!

    lazy var collectionAdapter: IGListAdapter = {
        return IGListAdapter(updater: IGListAdapterUpdater(),
                             viewController: self,
                             workingRangeSize: 0)
    }()

    var surface: DayScheduleSurface!

    override func viewDidLoad() {
        super.viewDidLoad()

        setupCollectionView()
    }

    private func setupCollectionView() {

        let layout = CalendarViewFlowLayout()
        collectionAdapter.collectionView = collectionView

        collectionAdapter.dataSource = self

        collectionView!.collectionViewLayout = layout
        collectionView!.contentInset = UIEdgeInsets(top:    15.0,
                                                         left:   15.0,
                                                         bottom: 75.0,
                                                         right:  15.0)

        collectionView!.alwaysBounceVertical = true
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
        self.collectionAdapter.performUpdates(animated: true)
    }
}

extension DayScheduleViewController: IGListAdapterDataSource {
    func listAdapter(_ listAdapter: IGListAdapter, sectionControllerFor object: Any) -> IGListSectionController {
        return ScheduleSectionController()
    }

    func objects(for listAdapter: IGListAdapter) -> [IGListDiffable] {
        return surface.entries.diffable()
    }

    func emptyView(for listAdapter: IGListAdapter) -> UIView? {
        return nil
    }
}

class ScheduleSectionController: IGListSectionController, IGListSectionType {
    var scheduleEntry: ScheduleEntry?

    override init() {
        super.init()
        inset = UIEdgeInsets(top: 0, left: 0, bottom: 15, right: 0)
    }

    func numberOfItems() -> Int {
        return 1
    }

    func sizeForItem(at index: Int) -> CGSize {
        let targetSize = CGSize(width: targetCellWidth, height: 100000000)

        switch scheduleEntry! {
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

    func didUpdate(to object: Any) {
        scheduleEntry = (object as? ScheduleEntryWrapper)?.scheduleEntry
    }

    func cellForItem(at index: Int) -> UICollectionViewCell {
        var cell: UICollectionViewCell!

        // Configure the cell

        switch scheduleEntry! {
        case .event(let event):
            cell = collectionContext!.dequeueReusableCell(withNibName: "EventViewCell",
                                                          bundle: nil,
                                                          for: self,
                                                          at: index)
            (cell as! EventViewCell).configure(with: event)

        case .openTime(let openTime):
            cell = collectionContext!.dequeueReusableCell(withNibName: "OpenTimeViewCell",
                                                          bundle: nil,
                                                          for: self,
                                                          at: index)
            (cell as! OpenTimeViewCell).configure(with: openTime)
        }

        self.configureCellWidth(cell)
        
        return cell
    }

    func didSelectItem(at index: Int) {
        return
    }

    fileprivate var targetCellWidth: CGFloat {
        return collectionContext!.containerSize.width
    }

    private lazy var prototypeEventCell: EventViewCell = {
        return Bundle.main.loadNibNamed("EventViewCell", owner: nil, options: nil)?.first as! EventViewCell
    }()

    private lazy var prototypeOpenTimeEventCell: OpenTimeViewCell = {
        return Bundle.main.loadNibNamed("OpenTimeViewCell", owner: nil, options: nil)?.first as! OpenTimeViewCell
    }()

    func configureCellWidth(_ cell: UICollectionViewCell) {
        cell.contentView.widthAnchor.constraint(equalToConstant: targetCellWidth).isActive = true
    }
}


