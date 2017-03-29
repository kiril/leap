//
//  InitialViewController.swift
//  Leap
//
//  Created by Chris Ricca on 3/28/17.
//  Copyright © 2017 Single Leap, Inc. All rights reserved.
//

import UIKit

class InitialViewController: UIViewController {
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        launchDebugViewController()
    }

    private func launchDebugViewController() {

        if true {
            presentCalendarViewController()
        }


    }

    private func presentCalendarViewController() {
        let debugEventViewController = UIStoryboard(name: "LocalCalendar", bundle: nil).instantiateInitialViewController()!

        self.present(debugEventViewController,
                     animated: true,
                     completion: nil)
    }
}
