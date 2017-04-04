//
//  UIPageViewController.swift
//  Leap
//
//  Created by Chris Ricca on 4/3/17.
//  Copyright © 2017 Single Leap, Inc. All rights reserved.
//

import UIKit

extension UIPageViewController {
    func turnPage(direction: UIPageViewControllerNavigationDirection = .forward,
                  animated: Bool = true) {
        guard   let previousViewControllers = viewControllers,
                let currentPage = previousViewControllers.first else { return }

        var nextVC: UIViewController?

        switch direction {
        case .forward:
            nextVC = dataSource?.pageViewController(self, viewControllerAfter: currentPage)
        case .reverse:
            nextVC = dataSource?.pageViewController(self, viewControllerBefore: currentPage)
        }

        guard let next = nextVC else { return }

        setViewControllers([next],
                           direction: direction,
                           animated: animated) { finished in

                            self.delegate?.pageViewController?(self, didFinishAnimating: finished,
                                                               previousViewControllers: previousViewControllers,
                                                               transitionCompleted: finished)
        }
    }
}
