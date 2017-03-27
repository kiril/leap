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

class CalendarCollectionViewController: UICollectionViewController {

    let scheduleViewModel: DayScheduleShell = {
        // mocking out entries

        var entries = [ScheduleEntry]()

        for i in 2...4 {
            let event = EventShell(mockData: ["title": "testing", "time_range": "\(i)pm - \(i+1)pm"])
            let eventEntry = ScheduleEntry.from(event: event)
            entries.append(eventEntry)
        }

        entries.append(ScheduleEntry.from(openTimeStart: nil, end: nil))

        let eventEntry = ScheduleEntry.from(eventId: "")
        entries.append(eventEntry)

        return DayScheduleShell(mockData: ["entries": entries])
    }()

    override func viewDidLoad() {
        super.viewDidLoad()

        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false
//        self.automaticallyAdjustsScrollViewInsets = false
        // Register cell classes
        self.collectionView!.register(UINib(nibName: "EventViewCell", bundle: nil), forCellWithReuseIdentifier: reuseIdentifier)

        let layout = CalendarViewFlowLayout()

        self.collectionView!.collectionViewLayout = layout
        self.collectionView!.contentInset = UIEdgeInsets(top: 15.0, left: 15.0, bottom: 0.0, right: 15.0)

//        self.collectionView!.delegate = self

        // Do any additional setup after loading the view.
    }

    override func viewWillAppear(_ animated: Bool) {
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
        return scheduleViewModel.entries.value.count
    }

    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: reuseIdentifier, for: indexPath) as! EventViewCell
    
        // Configure the cell

        let entry = scheduleViewModel.entries.value[indexPath.row]

        switch entry {
        case .event(let event):
            self.configureCell(cell, forEvent: event)

        case .openTime(let openTime):
            // for now, just hack in a new event view model since we don't have an open time view to display
            let event = EventShell(id: "", data:[:])
            self.configureCell(cell, forEvent: event)
        }

        return cell
    }


    func configureCell(_ cell: EventViewCell, forEvent event: EventShell) {
        cell.timeLabel.text = event.timeRange.value
        cell.titleLabel.text = event.title.value
        let targetWidth = collectionView!.bounds.size.width - 30
        cell.contentView.widthAnchor.constraint(equalToConstant: targetWidth).isActive = true
    }

    // MARK: UICollectionViewDelegate


}

extension CalendarCollectionViewController: UICollectionViewDelegateFlowLayout {
//    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
//        return UIEdgeInsets(top: 0.0, left: 15.0, bottom: 0.0, right: 15.0)
//    }
}
