//
//  WeekOverviewViewController.swift
//  Leap
//
//  Created by Chris Ricca on 4/1/17.
//  Copyright © 2017 Single Leap, Inc. All rights reserved.
//

import UIKit

class WeekOverviewViewController: UIViewController, StoryboardLoadable {

    @IBOutlet var dayButtons: [UIButton]!

    var surface: WeekOverviewSurface?

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        for (index, button) in dayButtons.enumerated() {
            let title = surface?.days[index].overviewDescription
            button.setTitle(title, for: .normal)
        }
    }
}
