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
    func tapped(on event: EventSurface) {
        let detail = EventDetailViewController()
        detail.event = event
        detail.entries = self.entries
        self.navigationController?.pushViewController(detail, animated: true)
    }

    func selected(response: EventResponse, for event: EventSurface) {
        if let recurring = event as? RecurringEventSurface,
            recurring.responseNeedsClarification(for: response) {
            let alert = recurring.recurringUpdateOptions(for: recurring.verb(for: response)) { scope in
                switch scope {
                case .none:
                    break // this is Cancel tapped

                case .series:
                    recurring.respond(with: response, forceDisplay: true)
                    self.navigationController!.popViewController(animated: true)

                case .event:
                    recurring.respond(with: response, forceDisplay: true, detaching: true)
                    self.navigationController!.popViewController(animated: true)
                }
            }
            self.present(alert, animated: true)
        } else {
            event.respond(with: response, forceDisplay: true)
            self.navigationController!.popViewController(animated: true)
        }
    }

    func hitReminder(for event: EventSurface) {
        event.hackyShowAsReminder()
        self.navigationController!.popViewController(animated: true)
    }
}
