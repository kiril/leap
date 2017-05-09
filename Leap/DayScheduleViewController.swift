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



let TITLE_MAX = 20



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

                alert.addAction(UIAlertAction(title: "Leave \"\(first.title.value.truncate(to: TITLE_MAX, in: .end))\" early", style: .destructive) { action in callback(TimeConflictResolution.leaveEarly) })
                alert.addAction(UIAlertAction(title: "Split the difference", style: .default) { action in callback(.splitEvenly) })

            case .left:
                let second = event.departureTime.value > other.departureTime.value ? event : other

                alert.addAction(UIAlertAction(title: "Join \"\(second.title.value.truncate(to: TITLE_MAX, in: .end))\" late", style: .destructive) { action in callback(.arriveLate) })
                alert.addAction(UIAlertAction(title: "Split the difference", style: .default) { action in callback(.splitEvenly) })

            }

        case .staggered:
            let first = event.startTime.value < other.startTime.value ? event : other
            let second = first == event ? other : event

            alert.addAction(UIAlertAction(title: "Leave \"\(first.title.value.truncate(to: TITLE_MAX, in: .end))\" early", style: .destructive) {
                action in callback(.leaveEarly) })
            alert.addAction(UIAlertAction(title: "Join \"\(second.title.value.truncate(to: TITLE_MAX, in: .end))\" late", style: .destructive) {
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


        func finish(by resolution: TimeConflictResolution, detaching: Bool) {
            let (a, b) = event.resolveConflict(with: other, in: overlap, by: resolution, detaching: detaching)
            callback(a, b)
        }

        let alert = UIAlertController(title: "Scheduling Conflict",
                                      message: "\"\(event.title.value)\" and \"\(other.title.value)\" overlap.",
            preferredStyle: .actionSheet)

        alert.addAction(UIAlertAction(title: "\(event.verb(for: .no)) \"\(other.title.value.truncate(to: TITLE_MAX, in: .end))\"", style: .destructive) {
            action in

            if let recurring = event as? RecurringEventSurface {
                let alert = recurring.recurringUpdateOptions(for: event.verb(for: .no)) { scope in
                    switch scope {
                    case .series:
                        finish(by: .decline(side: .right), detaching: false)

                    case .event:
                        finish(by: .decline(side: .right), detaching: true)

                    case .none:
                        return //canceled
                    }
                }

                self.present(alert, animated: true)
            }
            
            finish(by: .decline(side: .right), detaching: false)
        })
        alert.addAction(UIAlertAction(title: "\(event.verb(for: .no)) \"\(event.title.value.truncate(to: TITLE_MAX, in: .end))\"", style: .destructive) {
            action in

            if let recurring = event as? RecurringEventSurface {
                let alert = recurring.recurringUpdateOptions(for: event.verb(for: .no)) { scope in
                    switch scope {
                    case .series:
                        finish(by: .decline(side: .left), detaching: false)

                    case .event:
                        finish(by: .decline(side: .left), detaching: true)

                    case .none:
                        return //canceled
                    }
                }

                self.present(alert, animated: true)
            }

            finish(by: .decline(side: .left), detaching: false)
        })

        alert.addAction(UIAlertAction(title: "Split time between events", style: .default) {
            action in

            if let recurring = event as? RecurringEventSurface, other is RecurringEventSurface {
                switch overlap {
                case .identical:
                    let alert = recurring.recurringUpdateOptions(for: "Split time") { scope in
                        switch scope {
                        case .series:
                            finish(by: .splitEvenly, detaching: false)

                        case .event:
                            finish(by: .splitEvenly, detaching: true)

                        case .none:
                            return // canceled
                        }
                    }

                    self.present(alert, animated: true)

                default:
                    self.presentSplitOptions(for: event, and: other) { resolution in
                        let alert = recurring.recurringUpdateOptions(for: "Split time") { scope in
                            switch scope {
                            case .series:
                                finish(by: resolution, detaching: false)

                            case .event:
                                finish(by: resolution, detaching: true)

                            case .none:
                                return //canceled
                            }
                        }

                        self.present(alert, animated: true)
                    }
                }

            } else {

                switch overlap {
                case .identical: // there are no other option
                    finish(by: .splitEvenly, detaching: true)

                default:
                    self.presentSplitOptions(for: event, and: other) {
                        finish(by: $0, detaching: true)
                    }
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
                        recurring.respond(with: response, forceDisplay: true, detaching: true)
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

    func updatedTimePerspective(on cell: EventViewCell, for event: EventSurface) {
        event.isShinyNew = false
        collectionAdapter.performUpdates(animated: true, completion: nil)
    }
}

extension DayScheduleViewController: OpenTimeSectionControllerDelegate {
    func didTapEvent(eventId: String, on openTimeSection: OpenTimeSectionController) {
        // probably shouldn't go through openTime to get the event (either pass event or fetch by Id globally...
        // will do the latter when Recurring vs. one-time events are both fetchable by id.
        guard let event = openTimeSection.openTime.event(forId: eventId) else { return }
        presentEvent(event: event)
    }
}

extension DayScheduleViewController: SourceIdentifiable {
    var sourceId: String { return "DayScheduleVC" }
}


extension DayScheduleViewController: SurfaceObserver {
    func surfaceDidChange(_ surface: Surface) {
        collectionAdapter.performUpdates(animated: true)
    }
}

extension DayScheduleViewController: IGListAdapterDataSource {
    func listAdapter(_ listAdapter: IGListAdapter, sectionControllerFor object: Any) -> IGListSectionController {
        if let scheduleWrapper = object as? ScheduleEntryWrapper {
            switch scheduleWrapper.scheduleEntry {
            case .openTime:
                return OpenTimeSectionController(delegate: self)
            case .event:
                return EventSectionController(eventViewCellDelegate: self, day: self.surface.day.gregorianDay)
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
