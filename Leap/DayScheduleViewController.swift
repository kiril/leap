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
    func presentSplitOptions(for event: EventSurface, and other: EventSurface, respondingTo respondee: EventSurface? = nil, with response: EventResponse? = nil) {

        let alert = UIAlertController(title: "Split Time",
                                      message: "Between \"\(event.title.value)\" and \"\(other.title.value)\" overlap.",
            preferredStyle: .actionSheet)

        let overlap = event.intersection(with: other)

        func respond() {
            if let respondee = respondee, let response = response {
                respondee.respond(with: response)
            }
        }

        switch overlap {
        case .identical:

            let split = UIAlertAction(title: "Split the difference", style: .default) {
                action in
                event.splitTime(with: other, for: overlap)
                respond()
            }
            alert.addAction(split)

        case let .justified(direction):
            switch direction {
            case .right:
                let first = event.startTime.value < other.startTime.value ? event : other
                let second = first == event ? other : event

                let leaveEarly = UIAlertAction(title: "Leave \"\(first.title.value.truncate(to: 35, in: .end))\" early", style: .destructive) {
                    action in
                    first.leaveEarly(for: second)
                    respond()
                }
                alert.addAction(leaveEarly)

                let split = UIAlertAction(title: "Split the difference", style: .default) {
                    action in
                    event.splitTime(with: other, for: overlap)
                    respond()
                }
                alert.addAction(split)

            case .left:
                let first = event.endTime.value < other.endTime.value ? event : other
                let second = first == event ? other : event

                let joinLate = UIAlertAction(title: "Join \"\(second.title.value.truncate(to: 35, in: .end))\" late", style: .destructive) {
                    action in
                    second.joinLate(for: first)
                    respond()
                }
                alert.addAction(joinLate)

                let split = UIAlertAction(title: "Split the difference", style: .default) {
                    action in
                    event.splitTime(with: other, for: overlap)
                    respond()
                }
                alert.addAction(split)

            }

        case .staggered:
            let first = event.startTime.value < other.startTime.value ? event : other
            let second = first == event ? other : event

            let leaveEarly = UIAlertAction(title: "Leave \"\(first.title.value.truncate(to: 35, in: .end))\" early", style: .destructive) {
                action in
                first.leaveEarly(for: second)
                respond()
            }
            let joinLate = UIAlertAction(title: "Join \"\(second.title.value.truncate(to: 35, in: .end))\" late", style: .destructive) {
                action in
                second.joinLate(for: first)
                respond()
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

        func respond() {
            if let respondee = respondee, let response = response {
                respondee.respond(with: response)
            }
        }

        let title = respondee == nil ? "Fix Conflicting Events" : "Event Conflict"
        let alert = UIAlertController(title: title,
                                      message: "\"\(event.title.value)\" and \"\(other.title.value)\" overlap.",
            preferredStyle: .actionSheet)

        let declineOther = UIAlertAction(title: "Decline \"\(other.title.value.truncate(to: 35, in: .middle))\"", style: .destructive) {
            action in
            other.respond(with: .no)
            if let response = response, let respondee = respondee, respondee != other {
                respondee.respond(with: response)
            }
        }
        let declineThis = UIAlertAction(title: "Decline \"\(event.title.value.truncate(to: 35, in: .middle))\"", style: .destructive) {
            action in
            event.respond(with: .no)
            if let response = response, let respondee = respondee, respondee != event {
                respondee.respond(with: response)
            }
        }

        alert.addAction(declineOther)
        alert.addAction(declineThis)

        let split = UIAlertAction(title: "Split time between events", style: .default) {
            action in
            switch overlap {
            case .identical: // there are no other option
                event.splitTime(with: other, for: overlap)
                respond()

            default:
                self.presentSplitOptions(for: event, and: other, respondingTo: respondee, with: response)
            }
        }
        alert.addAction(split)

        if respondee != nil {
            let keep = UIAlertAction(title: "Join now, fix later", style: .default) {
                action in
                respond()
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
            if event.isRecurring.value && event.responseNeedsClarification(for: response), let recurring = event as? RecurringEventSurface {
                let alert = recurring.recurringResponseOptions(for: response) { scope in
                    switch scope {
                    case .none:
                        break
                    case .series:
                        recurring.respond(with: response, forceDisplay: true)
                    case .event:
                        recurring.respond(with: response, forceDisplay: true)
                    }
                }
                self.present(alert, animated: true)

            } else {
                event.respond(with: response, forceDisplay: true)
            }
        }
    }

    func tapReceived(on: EventViewCell, for event: EventSurface) {
        presentEvent(event: event)
    }

    func presentEvent(event: EventSurface) {
        let eventViewController = EventDetailViewController()
        eventViewController.event = event
        eventViewController.entries = self.surface.entries
        self.navigationController?.pushViewController(eventViewController, animated: true)
    }
}

extension DayScheduleViewController: OpenTimeSectionControllerDelegate {
    func didTapEvent(eventId: String, on openTimeSection: OpenTimeSectionController) {
        guard let event = EventSurface.load(byId: eventId) else { return }
        presentEvent(event: event)
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
        if let scheduleWrapper = object as? ScheduleEntryWrapper {
            switch scheduleWrapper.scheduleEntry {
            case .openTime:
                return OpenTimeSectionController(delegate: self)
            case .event:
                return EventSectionController(eventViewCellDelegate: self)
            }
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
        let reminders = (surface.reminderList as [IGListDiffable])

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
