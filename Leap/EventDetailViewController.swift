//
//  EventDetailViewController.swift
//  Leap
//
//  Created by Kiril Savino on 4/27/17.
//  Copyright © 2017 Single Leap, Inc. All rights reserved.
//

import UIKit

class EventDetailViewController: UIViewController {

    var event: EventSurface!
    var entries: [ScheduleEntry]!

    override func loadView() {
        let eventDetail = EventDetailView.instanceFromNib()
        eventDetail.entries = entries
        eventDetail.configure(with: self.event)
        self.view = eventDetail
        self.title = "Details"
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
}
