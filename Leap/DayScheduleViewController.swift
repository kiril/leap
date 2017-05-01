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

}

extension DayScheduleViewController: EventViewCellDelegate {
    func fixConflictTapped(on: EventViewCell, for event: EventSurface) {
        let alert = UIAlertController(title: "Fix Conflict",
                                      message: "OMG",
                                      preferredStyle: .actionSheet)

        let cancel = UIAlertAction(title: "Cancel", style: .cancel)

        var conflictingEvent: EventSurface!
        for entry in surface.entries {
            switch entry {
            case let .event(other):
                if other.isEligibleForConflict && other.intersectsWith(event) {
                    conflictingEvent = other
                    break
                }
            default:
                break
            }
        }

        let declineOther = UIAlertAction(title: "Decline \(conflictingEvent.title.value)", style: .destructive)
        let declineThis = UIAlertAction(title: "Decline \(event.title.value)", style: .destructive)
        let split = UIAlertAction(title: "Split Time Between Events", style: .default)

        alert.addAction(declineOther)
        alert.addAction(declineThis)
        alert.addAction(split)
        alert.addAction(cancel)

        self.present(alert, animated: true)
    }

    func tapReceived(on: EventViewCell, for event: EventSurface) {
        let eventViewController = EventDetailViewController()
        eventViewController.event = event
        eventViewController.entries = self.surface.entries
        self.navigationController?.pushViewController(eventViewController, animated: true)
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
        if object is ScheduleEntryWrapper {
            return ScheduleSectionController(eventViewCellDelegate: self)
        }
        else if object is ReminderSurface ||
                object is NoRemindersPlaceholderObject {
            return ReminderSectionController()
        }
        else if object is VerticalSpacingPlaceholderObject {
            return SpacingSectionController()
        }
        else {
            fatalError("Can't find an appropriate listAdapter for: \(object)")
        }
    }

    func objects(for listAdapter: IGListAdapter) -> [IGListDiffable] {
        let reminders = (surface.reminders.value as [IGListDiffable])

        var emptyReminderPlaceholder = [IGListDiffable]()
        if reminders.isEmpty {
            emptyReminderPlaceholder = [NoRemindersPlaceholderObject()]
        }

        let spacing = [VerticalSpacingPlaceholderObject(height: 15)] as [IGListDiffable]
        let entries = (surface.entries.diffable() as [IGListDiffable])

        return emptyReminderPlaceholder + reminders + spacing + entries
    }

    func emptyView(for listAdapter: IGListAdapter) -> UIView? {
        return nil
    }
}

