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

private let reuseIdentifier = "EventViewCell"

class CalendarViewController: UICollectionViewController {

    let eventStore = EKEventStore()
    var calendars = [EKCalendar]()

    var eventsForTheDay: [EKEvent] {
        let calendar = NSCalendar.current
        let startOfDay = calendar.startOfDay(for: Date())
        let endOfDay = calendar.date(bySettingHour: 23, minute: 59, second: 59, of: Date())!

        let todayPredicate = eventStore.predicateForEvents(withStart: startOfDay,
                                                           end: endOfDay,
                                                           calendars: nil)

        return eventStore.events(matching: todayPredicate)
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Register cell classes
        self.collectionView!.register(UINib(nibName: "EventViewCell", bundle: nil), forCellWithReuseIdentifier: reuseIdentifier)

        let layout = CalendarViewFlowLayout()
        layout.estimatedItemSize = CGSize(width: self.collectionView!.bounds.size.width, height: 100)
        self.collectionView!.collectionViewLayout = layout
        self.collectionView!.alwaysBounceVertical = true

        // Do any additional setup after loading the view.
    }

    override func viewWillAppear(_ animated: Bool) {
        requestCalendarAccess()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using [segue destinationViewController].
        // Pass the selected object to the new view controller.
    }
    */

    // MARK: UICollectionViewDataSource

    override func numberOfSections(in collectionView: UICollectionView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 1
    }


    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of items
        return eventsForTheDay.count
    }

    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: reuseIdentifier, for: indexPath) as! EventViewCell
    
        // Configure the cell

        let event = eventsForTheDay[indexPath.row]
        self.configureCell(cell, forEvent: event)
        return cell
    }

    func configureCell(_ cell: EventViewCell, forIndexPath indexPath: IndexPath) {
        configureCell(cell, forEvent: eventsForTheDay[indexPath.row])
    }

    func configureCell(_ cell: EventViewCell, forEvent event: EKEvent) {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mma"

        cell.timeLabel.text = "\(formatter.string(from: event.startDate))-\(formatter.string(from: event.endDate))".lowercased()
        cell.titleLabel.text = event.title
        cell.widthAnchor.constraint(equalToConstant: collectionView!.bounds.size.width).isActive = true

    }

    private func requestCalendarAccess() {
        eventStore.requestAccess(to: .event) { (success, error) in
            if success {
                self.calendars = self.eventStore.calendars(for: .event)
                self.collectionView?.reloadData()
            }
        }
    }

    // MARK: UICollectionViewDelegate


    /*
    // Uncomment this method to specify if the specified item should be highlighted during tracking
    override func collectionView(_ collectionView: UICollectionView, shouldHighlightItemAt indexPath: IndexPath) -> Bool {
        return true
    }
    */

    /*
    // Uncomment this method to specify if the specified item should be selected
    override func collectionView(_ collectionView: UICollectionView, shouldSelectItemAt indexPath: IndexPath) -> Bool {
        return true
    }
    */

    /*
    // Uncomment these methods to specify if an action menu should be displayed for the specified item, and react to actions performed on the item
    override func collectionView(_ collectionView: UICollectionView, shouldShowMenuForItemAt indexPath: IndexPath) -> Bool {
        return false
    }

    override func collectionView(_ collectionView: UICollectionView, canPerformAction action: Selector, forItemAt indexPath: IndexPath, withSender sender: Any?) -> Bool {
        return false
    }

    override func collectionView(_ collectionView: UICollectionView, performAction action: Selector, forItemAt indexPath: IndexPath, withSender sender: Any?) {
    
    }
    */

}

//extension CalendarViewController: UICollectionViewDelegateFlowLayout {
//    func heightForEventCell(atIndexPath indexPath: IndexPath, collectionView: UICollectionView) -> CGFloat {
////        struct StaticCellHolder {
////            static var sizingCell: EventViewCell?
////        }
////        if StaticCellHolder.sizingCell == nil {
////            StaticCellHolder.sizingCell = collectionView.dequeueReusableCell(withReuseIdentifier: reuseIdentifier, for: indexPath) as? EventViewCell
////        }
////        let sizingCell = collectionView.dequeueReusableCell(withReuseIdentifier: reuseIdentifier, for: indexPath) as! EventViewCell
//
//        let sizingCell = Bundle.main.loadNibNamed("EventViewCell", owner: nil, options: nil)?.first as! EventViewCell
//
//        self.configureCell(sizingCell, forIndexPath: indexPath)
//        return self.calculateHeight(forCell: sizingCell)
//    }
//
//    func calculateHeight(forCell sizingCell: EventViewCell) -> CGFloat {
//        sizingCell.setNeedsLayout()
//        sizingCell.layoutIfNeeded()
//        return sizingCell.contentView.systemLayoutSizeFitting(UILayoutFittingCompressedSize).height + 1
//    }
//
//    func collectionView(_ collectionView: UICollectionView,
//                        layout collectionViewLayout: UICollectionViewLayout,
//                        sizeForItemAt indexPath: IndexPath) -> CGSize {
//        return CGSize(width: self.collectionView!.frame.width,
//                      height: self.heightForEventCell(atIndexPath: indexPath, collectionView: collectionView))
//    }
//}
