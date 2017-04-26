//
//  ReminderSectionController.swift
//  Leap
//
//  Created by Chris Ricca on 4/25/17.
//  Copyright © 2017 Single Leap, Inc. All rights reserved.
//

import Foundation

import Foundation
import IGListKit

class ReminderSectionController: IGListSectionController, IGListSectionType {
    var reminder: ReminderSurface?

    override init() {
        super.init()
        inset = UIEdgeInsets(top: 5, left: 0, bottom: 5, right: 0)
    }

    func numberOfItems() -> Int {
        return 1
    }

    func sizeForItem(at index: Int) -> CGSize {
        let targetSize = CGSize(width: targetCellWidth, height: 100000000)
        guard let reminder = reminder else { return CGSize.zero }

        configureCellWidth(prototypeReminderCell)
        prototypeReminderCell.configure(with: reminder)
        let size = prototypeReminderCell.systemLayoutSizeFitting(targetSize)
        return size
    }

    func didUpdate(to object: Any) {
        reminder = object as? ReminderSurface
    }

    func cellForItem(at index: Int) -> UICollectionViewCell {
        var cell: UICollectionViewCell!
        guard let reminder = reminder else { return UICollectionViewCell() }

        // Configure the cell

        cell = collectionContext!.dequeueReusableCell(withNibName: "ReminderCollectionViewCell",
                                                      bundle: nil,
                                                      for: self,
                                                      at: index)

        (cell as! ReminderCollectionViewCell).configure(with: reminder)

        configureCellWidth(cell)

        return cell
    }

    func didSelectItem(at index: Int) {
        return
    }

    fileprivate var targetCellWidth: CGFloat {
        return collectionContext!.containerSize.width
    }

    private lazy var prototypeReminderCell: ReminderCollectionViewCell = {
        return Bundle.main.loadNibNamed("ReminderCollectionViewCell", owner: nil, options: nil)?.first as! ReminderCollectionViewCell
    }()

    func configureCellWidth(_ cell: UICollectionViewCell) {
        cell.contentView.widthAnchor.constraint(equalToConstant: targetCellWidth).isActive = true
    }
}
