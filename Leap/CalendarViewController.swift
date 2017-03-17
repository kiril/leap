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

    let scheduleViewModel = DayScheduleViewModel(dayId: Calendar.current.today.id)

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
        return scheduleViewModel.entries.count
    }

    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: reuseIdentifier, for: indexPath) as! EventViewCell
    
        // Configure the cell

        let entry = scheduleViewModel.entries[indexPath.row]

        switch entry {
        case .event(let event):
            self.configureCell(cell, forEvent: event)

        case .openTime(let openTime):
            // for now, just hack in a new event view model since we don't have an open time view to display
            let event = EventViewModel(id: "")
            self.configureCell(cell, forEvent: event)
        }

        return cell
    }

    func configureCell(_ cell: EventViewCell, forEvent event: EventViewModel) {
        cell.timeLabel.text = event.timeRange
        cell.titleLabel.text = event.title
        cell.widthAnchor.constraint(equalToConstant: collectionView!.bounds.size.width).isActive = true

    }

    // MARK: UICollectionViewDelegate


}
