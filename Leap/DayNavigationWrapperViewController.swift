//
//  DayNavigationWrapperViewController.swift
//  Leap
//
//  Created by Chris Ricca on 4/14/17.
//  Copyright © 2017 Single Leap, Inc. All rights reserved.
//

import UIKit

class DayNavigationWrapperViewController: UIViewController {

    var dayNavigationController: DayNavigationViewController!

    override func viewDidLoad() {
        super.viewDidLoad()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        guard let name = segue.identifier else { return }

        if name == "embeddedNavVCSegue" {
            let navVC = segue.destination as! UINavigationController
            dayNavigationController = navVC.viewControllers.first as! DayNavigationViewController
        }
    }
}

extension DayNavigationWrapperViewController: SelectedTabTappable {
    func selectedTabWasTapped(on tabBarController: MainTabBarController) {
        dayNavigationController.selectedTabWasTapped(on: tabBarController)
    }
}
