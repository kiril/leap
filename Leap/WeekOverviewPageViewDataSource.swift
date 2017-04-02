//
//  WeekOverviewPageViewDelegate.swift
//  Leap
//
//  Created by Chris Ricca on 4/1/17.
//  Copyright © 2017 Single Leap, Inc. All rights reserved.
//

import UIKit


class WeekOverviewPageViewDataSource: NSObject, UIPageViewControllerDataSource {

    func pageViewController(_ pageViewController: UIPageViewController,
                            viewControllerAfter viewController: UIViewController) -> UIViewController? {
        let indexVC = viewController as! WeekOverviewViewController
        return viewControllerFor(surface: indexVC.surface?.weekAfter)
    }

    func pageViewController(_ pageViewController: UIPageViewController,
                            viewControllerBefore viewController: UIViewController) -> UIViewController? {
        let indexVC = viewController as! WeekOverviewViewController
        return viewControllerFor(surface: indexVC.surface?.weekBefore)
    }

    private func viewControllerFor(surface: WeekOverviewSurface?) -> UIViewController? {
        guard let surface = surface else { return nil }
        let vc = WeekOverviewViewController.loadFromStoryboard()
        vc.surface = surface
        return vc
    }

}
