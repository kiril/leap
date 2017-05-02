//
//  EventSectionController.swift
//  Leap
//
//  Created by Chris Ricca on 5/2/17.
//  Copyright © 2017 Single Leap, Inc. All rights reserved.
//

import Foundation
import IGListKit

class EventSectionController: IGListSectionController, IGListSectionType {
    var event: EventSurface!

    weak var eventViewCellDelegate: EventViewCellDelegate?

    init(eventViewCellDelegate: EventViewCellDelegate) {
        super.init()
        self.eventViewCellDelegate = eventViewCellDelegate

        inset = UIEdgeInsets(top: 0, left: 0, bottom: 15, right: 0)
    }

    func numberOfItems() -> Int {
        return 1
    }

    func sizeForItem(at index: Int) -> CGSize {
        let targetSize = CGSize(width: targetCellWidth, height: 100000000)
        configureCellWidth(prototypeEventCell)

        prototypeEventCell.configure(with: event)
        let size = prototypeEventCell.systemLayoutSizeFitting(targetSize)
        return size
    }

    func didUpdate(to object: Any) {
        let scheduleEntry = (object as! ScheduleEntryWrapper).scheduleEntry
        switch scheduleEntry {
        case let .event(event):
            self.event = event
        default:
            fatalError("Eek! The wrong schedule entry ended up in this EventSectionController")
        }
    }

    func cellForItem(at index: Int) -> UICollectionViewCell {
        let cell = collectionContext!.dequeueReusableCell(withNibName: "EventViewCell",
                                                          bundle: nil,
                                                          for: self,
                                                          at: index) as! EventViewCell
        cell.configure(with: event)
        cell.delegate = self.eventViewCellDelegate

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

    func configureCellWidth(_ cell: UICollectionViewCell) {
        cell.contentView.widthAnchor.constraint(equalToConstant: targetCellWidth).isActive = true
    }
}
