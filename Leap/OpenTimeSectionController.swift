//
//  OpenTimeSectionController.swift
//  Leap
//
//  Created by Chris Ricca on 5/2/17.
//  Copyright © 2017 Single Leap, Inc. All rights reserved.
//

import Foundation
import IGListKit

protocol OpenTimeSectionControllerDelegate: class {
    func didTapEvent(eventId: String, on openTimeSection: OpenTimeSectionController)
    func openTimeNeedsUpdate(openTime: OpenTimeViewModel, on openTimeSection: OpenTimeSectionController)
}

class OpenTimeSectionController: IGListSectionController, IGListSectionType {
    var openTime: OpenTimeViewModel!
    weak var delegate: OpenTimeSectionControllerDelegate?

    init(delegate: OpenTimeSectionControllerDelegate? = nil) {
        super.init()
        self.delegate = delegate
        inset = UIEdgeInsets(top: 0, left: 0, bottom: 15, right: 0)
    }

    func numberOfItems() -> Int {
        return 1 + openTime.possibleEventCount
    }

    func sizeForItem(at index: Int) -> CGSize {
        let targetSize = CGSize(width: targetCellWidth, height: 100000000)

        var size: CGSize!

        if index == 0 {
            // open time display itself
            configureCellWidth(prototypeOpenTimeCell)
            prototypeOpenTimeCell.configure(with: openTime)
            size = prototypeOpenTimeCell.systemLayoutSizeFitting(targetSize)
        } else {
            // possible event
            configureCellWidth(prototypeOpenTimePossibleEventCell)

            let event = openTime.possibleEvent(atIndex: index - 1)!
            prototypeOpenTimePossibleEventCell.configure(with: event)
            size = prototypeOpenTimePossibleEventCell.systemLayoutSizeFitting(targetSize)
        }

        return size
    }

    func didUpdate(to object: Any) {
        let scheduleEntry = (object as! ScheduleEntryWrapper).scheduleEntry
        switch scheduleEntry {
        case let .openTime(openTime):
            self.openTime = openTime
        default:
            fatalError("Eek! The wrong schedule entry ended up in this OpenTimeSectionController")
        }
    }

    func cellForItem(at index: Int) -> UICollectionViewCell {
        if index == 0 {
            // open time display itself

            let cell = collectionContext!.dequeueReusableCell(withNibName: "OpenTimeViewCell",
                                                              bundle: nil,
                                                              for: self,
                                                              at: index) as! OpenTimeViewCell
            cell.configure(with: openTime)
            cell.delegate = self
            configureCellWidth(cell)
            return cell
        } else {
            // possible event

            let cell = collectionContext!.dequeueReusableCell(withNibName: "OpenTimePossibleEventCollectionViewCell",
                                                              bundle: nil,
                                                              for: self,
                                                              at: index) as! OpenTimePossibleEventCollectionViewCell
            let event = openTime.possibleEvent(atIndex: index - 1)!
            cell.configure(with: event)
            configureCellWidth(cell)
            return cell
        }
    }

    func didSelectItem(at index: Int) {
        guard index > 0 else { return }
        let eventIndex = index - 1
        let eventId = openTime.possibleEventIds[eventIndex]

        delegate?.didTapEvent(eventId: eventId, on: self)
    }

    fileprivate var targetCellWidth: CGFloat {
        return collectionContext!.containerSize.width
    }

    private lazy var prototypeOpenTimeCell: OpenTimeViewCell = {
        return Bundle.main.loadNibNamed("OpenTimeViewCell", owner: nil, options: nil)?.first as! OpenTimeViewCell
    }()

    private lazy var prototypeOpenTimePossibleEventCell: OpenTimePossibleEventCollectionViewCell = {
        return Bundle.main.loadNibNamed("OpenTimePossibleEventCollectionViewCell",
                                        owner: nil,
                                        options: nil)?.first as! OpenTimePossibleEventCollectionViewCell
    }()

    func configureCellWidth(_ cell: UICollectionViewCell) {
        cell.contentView.widthAnchor.constraint(equalToConstant: targetCellWidth).isActive = true
    }
}

extension OpenTimeSectionController: OpenTimeViewCellDelegate {
    func updatedTimePerspective(on cell: OpenTimeViewCell, for openTime: OpenTimeViewModel) {
        delegate?.openTimeNeedsUpdate(openTime: openTime, on: self)
    }
}
