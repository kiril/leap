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

    override func viewWillAppear(_ animated: Bool) {
        var text = event.title.value
        if text.utf16.count > 12 {
            text = text.substring(to: text.index(text.startIndex, offsetBy: 9)) + "..."
        }
        let back = UIBarButtonItem(title: text, style: UIBarButtonItemStyle.plain, target: nil, action: nil)
        self.navigationItem.backBarButtonItem = back
    }

    override func loadView() {
        let eventDetail = EventDetailView.instanceFromNib()
        eventDetail.entries = entries
        eventDetail.delegate = self
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

extension EventDetailViewController: EventDetailViewDelegate {
    func eventTapped(with event: EventSurface) {
        let detail = EventDetailViewController()
        detail.event = event
        detail.entries = self.entries
        self.navigationController?.pushViewController(detail, animated: true)
    }

    func didChangeResponse(for event: EventSurface) {
        self.navigationController!.popViewController(animated: true)
    }
}
