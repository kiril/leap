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
    func presentSplitOptions(for event: EventSurface, and other: EventSurface) {

        let alert = UIAlertController(title: "Split Time",
                                      message: "Between \"\(event.title.value)\" and \"\(other.title.value)\" overlap.",
            preferredStyle: .actionSheet)

        let overlap = event.intersection(with: other)

        switch overlap {
        case .identical:

            let split = UIAlertAction(title: "Split the difference", style: .default) {
                action in
                event.splitTime(with: other, for: overlap)
            }
            alert.addAction(split)

        case let .justified(direction):
            switch direction {
            case .right:
                let first = event.startTime.value < other.startTime.value ? event : other
                let second = first == event ? other : event

                let leaveEarly = UIAlertAction(title: "Leave \"\(first.title.value.truncate(to: 25, in: .end))\" early", style: .destructive) {
                    action in
                    first.leaveEarly(for: second)
                }
                alert.addAction(leaveEarly)

                let split = UIAlertAction(title: "Split the difference", style: .default) {
                    action in
                    event.splitTime(with: other, for: overlap)
                }
                alert.addAction(split)

            case .left:
                let first = event.endTime.value < other.endTime.value ? event : other
                let second = first == event ? other : event

                let joinLate = UIAlertAction(title: "Join \"\(second.title.value.truncate(to: 25, in: .end))\" late", style: .destructive) {
                    action in
                    second.joinLate(for: first)
                }
                alert.addAction(joinLate)

                let split = UIAlertAction(title: "Split the difference", style: .default) {
                    action in
                    event.splitTime(with: other, for: overlap)
                }
                alert.addAction(split)

            }

        case .staggered:
            let first = event.startTime.value < other.startTime.value ? event : other
            let second = first == event ? other : event

            let leaveEarly = UIAlertAction(title: "Leave \"\(first.title.value.truncate(to: 25, in: .end))\" early", style: .destructive) {
                action in
                first.leaveEarly(for: second)
            }
            let joinLate = UIAlertAction(title: "Join \"\(second.title.value.truncate(to: 25, in: .end))\" late", style: .destructive) {
                action in
                second.joinLate(for: first)
            }

            alert.addAction(leaveEarly)
            alert.addAction(joinLate)

        case .none:
            return // wtf...?
        }

        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        
        self.present(alert, animated: true)
    }

    func resolve(overlap: Overlap, between event: EventSurface, and other: EventSurface, respondingTo respondee: EventSurface? = nil, with response: EventResponse? = nil) {
        let title = respondingTo == nil ? "Fix Conflicting Events" : "Event Conflict"
        let alert = UIAlertController(title: title,
                                      message: "\"\(event.title.value)\" and \"\(other.title.value)\" overlap.",
            preferredStyle: .actionSheet)

        let declineOther = UIAlertAction(title: "Decline \"\(other.title.value.truncate(to: 15, in: .middle))\"", style: .destructive) {
            action in
            other.respond(with: .no)
        }
        let declineThis = UIAlertAction(title: "Decline \"\(event.title.value.truncate(to: 15, in: .middle))\"", style: .destructive) {
            action in
            event.respond(with: .no)
        }

        alert.addAction(declineOther)
        alert.addAction(declineThis)

        let split = UIAlertAction(title: "Split time between events", style: .default) {
            action in
            switch overlap {
            case .identical: // there are no other option
                event.splitTime(with: other, for: overlap)

            default:
                self.presentSplitOptions(for: event, and: other)
            }
        }
        alert.addAction(split)

        if let respondee = respondee, let response = response {
            let keep = UIAlertAction(title: "Join without fixing conflict", style: .destructive) {
                action in
                respondee.respond(with: response)
            }
            alert.addAction(keep)
        }

        let cancel = UIAlertAction(title: "Cancel", style: .cancel)
        alert.addAction(cancel)

        self.present(alert, animated: true)
    }

    func fixConflictTapped(on: EventViewCell, for event: EventSurface) {

        guard let (overlap, other) = event.firstConflict(in: surface.entries.events) else { return }
        resolve(overlap: overlap, between: event, and: other)
    }

    func selectedNewEventResponse(_ response: EventResponse, on cell: EventViewCell, for event: EventSurface) {
        if response == .yes, let (overlap, other) = event.firstConflict(in: surface.entries.events, assumingCommitted: true) {
            resolve(overlap: overlap, between: event, and: other, respondingTo: event, with: response)

        } else {
            event.respond(with: response, forceDisplay: true)
        }
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

