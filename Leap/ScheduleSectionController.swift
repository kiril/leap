//
//  ScheduleSectionController.swift
//  Leap
//
//  Created by Chris Ricca on 4/25/17.
//  Copyright © 2017 Single Leap, Inc. All rights reserved.
//

import Foundation
import IGListKit

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
