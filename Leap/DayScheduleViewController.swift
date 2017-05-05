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
    func presentSplitOptions(for event: EventSurface, and other: EventSurface, andThen callback: @escaping (TimeConflictResolution) -> Void) {

        let alert = UIAlertController(title: "Split Time",
                                      message: "Between \"\(event.title.value)\" and \"\(other.title.value)\" overlap.",
            preferredStyle: .actionSheet)

        let overlap = event.intersection(with: other)

        switch overlap {
        case .identical:
            alert.addAction(UIAlertAction(title: "Split the difference", style: .default) { action in callback(.splitEvenly) })

        case let .justified(direction):
            switch direction {
            case .right:
                let first = event.arrivalTime.value < other.arrivalTime.value ? event : other

                alert.addAction(UIAlertAction(title: "Leave \"\(first.title.value.truncate(to: 35, in: .end))\" early", style: .destructive) { action in callback(TimeConflictResolution.leaveEarly) })
                alert.addAction(UIAlertAction(title: "Split the difference", style: .default) { action in callback(.splitEvenly) })

            case .left:
                let second = event.departureTime.value > other.departureTime.value ? event : other

                alert.addAction(UIAlertAction(title: "Join \"\(second.title.value.truncate(to: 35, in: .end))\" late", style: .destructive) { action in callback(.arriveLate) })
                alert.addAction(UIAlertAction(title: "Split the difference", style: .default) { action in callback(.splitEvenly) })

            }

        case .staggered:
            let first = event.startTime.value < other.startTime.value ? event : other
            let second = first == event ? other : event

            alert.addAction(UIAlertAction(title: "Leave \"\(first.title.value.truncate(to: 35, in: .end))\" early", style: .destructive) {
                action in callback(.leaveEarly) })
            alert.addAction(UIAlertAction(title: "Join \"\(second.title.value.truncate(to: 35, in: .end))\" late", style: .destructive) {
                action in callback(.arriveLate) })

        case .none:
            return // wtf...?
        }

        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel) { action in callback(.none) })
        
        self.present(alert, animated: true)
    }

    func resolve(overlap: Overlap, between event: EventSurface, and other: EventSurface) {
        return resolve(overlap: overlap, between: event, and: other, allowDefer: false, onResolve: { a, b in })
    }

    func resolve(overlap: Overlap, between event: EventSurface, and other: EventSurface, allowDefer: Bool, onResolve callback: @escaping (EventSurface, EventSurface) -> Void) {
        let alert = UIAlertController(title: "Scheduling Conflict",
                                      message: "\"\(event.title.value)\" and \"\(other.title.value)\" overlap.",
            preferredStyle: .actionSheet)

        alert.addAction(UIAlertAction(title: "Decline \"\(other.title.value.truncate(to: 35, in: .middle))\"", style: .destructive) {
            action in
            other.respond(with: .no)
            callback(event, other)
        })
        alert.addAction(UIAlertAction(title: "Decline \"\(event.title.value.truncate(to: 35, in: .middle))\"", style: .destructive) {
            action in
            event.respond(with: .no)
            callback(event, other)
        })

        alert.addAction(UIAlertAction(title: "Split time between events", style: .default) {
            action in

            func resolve(resolution: TimeConflictResolution) {
                var left = event
                var right = other

                switch resolution {
                case .leaveEarly:
                    // whichever starts first, we leave in time for the second
                    if left.arrivesEarlier(than: right) {
                        left = left.leaveEarly(for: right)
                    } else {
                        right = right.leaveEarly(for: left)
                    }

                case .arriveLate:
                    // whichever ends later, we arrive at when the first one is done
                    if left.departsLater(than: right) {
                        left = left.joinLate(for: right)
                    } else {
                        right = right.joinLate(for: left)
                    }

                case .splitEvenly:
                    (left, right) = left.splitTime(with: right, for: overlap)

                case .none:
                    return // cancel tapped
                }

                callback(left, right) // splitting will sometimes detach
            }

            if let recurring = event as? RecurringEventSurface, other is RecurringEventSurface {
                // TODO: switch the order of operations here (presentSplitOptions, and THEN ask about series vs. individual)
                let alert = recurring.recurringUpdateOptions(for: "Split time") { scope in
                    switch scope {
                    case .none:
                        return // canceled
                    case .series:
                        switch overlap {
                        case .identical:
                            let (a, b) = event.splitTime(with: other, for: overlap)
                            callback(a, b)

                        default:
                            self.presentSplitOptions(for: event, and: other, andThen: resolve)
                        }

                    case .event:
                        let detachedEvent = recurring.detach()!
                        switch overlap {
                        case .identical:
                            let (a, b) = detachedEvent.splitTime(with: other, for: overlap)
                            callback(a, b)

                        default:
                            self.presentSplitOptions(for: detachedEvent, and: other, andThen: resolve)
                        }
                    }
                }

                self.present(alert, animated: true)

            } else {

                switch overlap {
                case .identical: // there are no other option
                    let (a, b) = event.splitTime(with: other, for: overlap)
                    callback(a, b)

                default:
                    self.presentSplitOptions(for: event, and: other, andThen: resolve)
                }
            }
        })

        if allowDefer {
            alert.addAction(UIAlertAction(title: "Fix later", style: .default) {
                action in
                callback(event, other)
            })
        }

        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))

        self.present(alert, animated: true)
    }

    func fixConflictTapped(on: EventViewCell, for event: EventSurface) {
        guard let (overlap, other) = event.firstConflict(in: surface.entries.events) else { return }
        resolve(overlap: overlap, between: event, and: other)
    }

    func selectedNewEventResponse(_ response: EventResponse, on cell: EventViewCell, for event: EventSurface) {
        if response == .yes, let (overlap, other) = event.firstConflict(in: surface.entries.events, assumingCommitted: true) {
            resolve(overlap: overlap, between: event, and: other, allowDefer: true) { (newEvent, other) in
                event.isShinyNew = false // this is annoying... it's so the list diffable understands what to do
                newEvent.respond(with: response, forceDisplay: true)
            }

        } else {
            if event.isRecurring.value && event.responseNeedsClarification(for: response), let recurring = event as? RecurringEventSurface {
                let alert = recurring.recurringUpdateOptions(for: recurring.verb(for: response)) { scope in
                    switch scope {
                    case .none:
                        break
                    case .series:
                        recurring.respond(with: response, forceDisplay: true)
                    case .event:
                        recurring.respondDetaching(with: response, forceDisplay: true)
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
