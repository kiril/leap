//
//  LocalCalendarTableViewController.swift
//  Leap
//
//  Created by Chris Ricca on 3/16/17.
//  Copyright © 2017 Kiril Savino. All rights reserved.
//

import UIKit
import EventKit

class LocalCalendarTableViewController: UITableViewController {

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

        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem()
    }

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView,
                            cellForRowAt indexPath: IndexPath) -> UITableViewCell {

        let event = eventsForTheDay[indexPath.row]

        let cell = UITableViewCell()

        cell.textLabel?.text = event.title

        return cell
    }

    override func viewWillAppear(_ animated: Bool) {
        requestCalendarAccess()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    // MARK: - Table view data source


    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return eventsForTheDay.count
    }

    private func requestCalendarAccess() {
        eventStore.requestAccess(to: .event) { (success, error) in
            if success {
                self.calendars = self.eventStore.calendars(for: .event)
                self.tableView.reloadData()
            }
        }
    }

}
