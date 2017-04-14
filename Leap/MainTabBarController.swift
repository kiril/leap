//
//  MainTabBarController.swift
//  Leap
//
//  Created by Chris Ricca on 4/14/17.
//  Copyright © 2017 Single Leap, Inc. All rights reserved.
//

import UIKit

class MainTabBarController: UITabBarController {

    override func viewDidLoad() {
        super.viewDidLoad()
        self.delegate = self
    }
}

protocol SelectedTabTappable {
    func selectedTabWasTapped(on tabBarController: MainTabBarController)
}

extension MainTabBarController: UITabBarControllerDelegate {
    func tabBarController(_ tabBarController: UITabBarController,
                          shouldSelect viewController: UIViewController) -> Bool {

        if  let selectedTabTappable = viewController as? SelectedTabTappable,
            isSelected(tab: selectedTabTappable) {
            selectedTabTappable.selectedTabWasTapped(on: self)
        }

        return true
    }

    private func isSelected(tab: Any) -> Bool {
        if  let vc = tab as? UIViewController,
            let selected = selectedViewController {
            return vc == selected
        }
        return false
    }
}
