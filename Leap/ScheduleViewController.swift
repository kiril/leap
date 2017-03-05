//
//  ScheduleViewController.swift
//  Leap
//
//  Created by Kiril Savino on 12/28/16.
//  Copyright © 2016 Kiril Savino. All rights reserved.
//

import UIKit
import EventKit

class ScheduleViewController: UIViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func requestCalendarAccess(eventStore: EKEventStore) {
        eventStore.requestAccess(to: EKEntityType.event, completion: {
            (accessGranted: Bool, error: Error?) in
            
            if accessGranted == true {
                DispatchQueue.main.async(execute: {
                    self.loadCalendarData()
                })
            } else {
                DispatchQueue.main.async(execute: {
                    self.showNoPermissionAlert()
                })
            }
        })
    }
    
    func loadCalendarData() {
        NSLog("Loading calendar data")
    }
    
    func showNoPermissionAlert() {
        NSLog("oops, no permission")
    }
    
    func checkCalendarAuthorizationStatus(eventStore: EKEventStore) {
        let status = EKEventStore.authorizationStatus(for: EKEntityType.event)
        
        switch (status) {
        case EKAuthorizationStatus.notDetermined:
            // This happens on first-run
            requestCalendarAccess(eventStore: eventStore)
            break
        case EKAuthorizationStatus.authorized:
            // Things are in line with being able to show the calendars in the table view
            loadCalendarData()
            break
        case EKAuthorizationStatus.restricted, EKAuthorizationStatus.denied:
            // We need to help them give us permission
            showNoPermissionAlert()
            break
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        checkCalendarAuthorizationStatus(eventStore: appDelegate.eventStore!)
    }
    
    
}

