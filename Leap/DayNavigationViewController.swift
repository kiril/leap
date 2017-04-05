//
//  DayNavigationViewController.swift
//  Leap
//
//  Created by Chris Ricca on 4/3/17.
//  Copyright © 2017 Single Leap, Inc. All rights reserved.
//

import UIKit

class DayNavigationViewController: UIViewController, StoryboardLoadable {
    @IBOutlet weak var pageViewContainer: UIView!
    var titleView: DayScheduleTitleView!

    private lazy var daySchedulePageViewDataSource = DaySchedulePageViewDataSource()

    fileprivate var currentlySelectedDay: DaySurface? {
        guard let day = daySchedulePageViewController.viewControllers?.first as? DayScheduleViewController else {
            return nil
        }
        return day.surface.day
    }

    var daySchedulePageViewController: UIPageViewController!

    private func setupPageViewController() {
        daySchedulePageViewController = UIPageViewController(transitionStyle: .scroll,
                                                             navigationOrientation: .horizontal,
                                                             options: nil)

        daySchedulePageViewController.dataSource = daySchedulePageViewDataSource
        daySchedulePageViewController.delegate = self

        addChildViewController(daySchedulePageViewController)
        //        weekOverviewPageViewController.view.frame = CGRect.zero
        pageViewContainer.addSubview(daySchedulePageViewController.view)

        daySchedulePageViewController.view.leftAnchor.constraint(equalTo: pageViewContainer.leftAnchor).isActive = true
        daySchedulePageViewController.view.rightAnchor.constraint(equalTo: pageViewContainer.rightAnchor).isActive = true
        daySchedulePageViewController.view.topAnchor.constraint(equalTo: pageViewContainer.topAnchor).isActive = true
        daySchedulePageViewController.view.bottomAnchor.constraint(equalTo: pageViewContainer.bottomAnchor).isActive = true

        daySchedulePageViewController.didMove(toParentViewController: self)

        daySchedulePageViewController.view.translatesAutoresizingMaskIntoConstraints = false // HELPS
        daySchedulePageViewController.view.backgroundColor = UIColor.white

        //let initialDay = DayScheduleViewController.mockedEntriesFor(dayId: String(Calendar.current.today.id))
        let initialDay = DayScheduleSurface.load(dayId: Calendar.current.today.id)
        let initialDayVC = DayScheduleViewController.loadFromStoryboard()
        initialDayVC.surface = initialDay
        daySchedulePageViewController.setViewControllers([initialDayVC],
                                                          direction: .forward,
                                                          animated: false, completion: nil)

        updateTitleFor(vc: initialDayVC)
    }

    private func setupNavigation() {
        let titleNib = UINib(nibName: "DayScheduleTitleView", bundle: nil)
        titleView = titleNib.instantiate(withOwner: nil, options: nil).first as! DayScheduleTitleView

        let arrowNib = UINib(nibName: "NavigationToggleArrowView", bundle: nil)
        let arrowView = arrowNib.instantiate(withOwner: nil, options: nil).first as! UIView

        navigationItem.leftBarButtonItems = [
            barButtonItemFor(navView: arrowView),
            barButtonItemFor(navView: titleView)
        ]
    }

    private func barButtonItemFor(navView view: UIView) -> UIBarButtonItem {
        view.translatesAutoresizingMaskIntoConstraints = false
        let tap = UITapGestureRecognizer(target: self, action: #selector(didTapNavigation))
        view.addGestureRecognizer(tap)

        return UIBarButtonItem(customView: view)
    }

    @objc private func didTapNavigation() {
        let (navVC, weekVC) = WeekNavigationViewController.loadFromStoryboardWithNavController()

        navVC.modalPresentationStyle = .overCurrentContext
        navVC.modalTransitionStyle = .crossDissolve
        weekVC.delegate = self
        if let currentDayId = currentlySelectedDay?.id {
            weekVC.selectedDayId = currentDayId
        }

        present(navVC, animated: true, completion: nil)
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        setupNavigation()
        setupPageViewController()
        // Do any additional setup after loading the view.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
}

extension DayNavigationViewController: WeekNavigationViewControllerDelegate {
    func didSelectDay(dayId: String, on: WeekNavigationViewController) {
        guard let currentId = currentlySelectedDay?.intId else { return }

        guard dayId != String(currentId) else {
            dismiss(animated: true)
            return
        }

        let direction: UIPageViewControllerNavigationDirection = (Int(dayId)! > currentId) ? .forward : .reverse

        let dayVC = DayScheduleViewController.loadFromStoryboard()
        let surface = DayScheduleViewController.mockedEntriesFor(dayId: dayId)
        dayVC.surface = surface

        daySchedulePageViewController.setViewControllers([dayVC],
                                                         direction: direction,
                                                         animated: true)
        updateTitleFor(vc: dayVC)

        dismiss(animated: true)
    }
}

class DaySchedulePageViewDataSource: NSObject, UIPageViewControllerDataSource {
    func pageViewController(_ pageViewController: UIPageViewController,
                            viewControllerAfter viewController: UIViewController) -> UIViewController? {
        let indexVC = viewController as! DayScheduleViewController
        return viewControllerFor(surface: indexVC.surface.day.dayAfter)
    }

    func pageViewController(_ pageViewController: UIPageViewController,
                            viewControllerBefore viewController: UIViewController) -> UIViewController? {
        let indexVC = viewController as! DayScheduleViewController
        return viewControllerFor(surface: indexVC.surface.day.dayBefore)
    }

    private func viewControllerFor(surface: DaySurface) -> UIViewController? {
        guard let id = surface.id else { return nil }
        let vc = DayScheduleViewController.loadFromStoryboard()
        vc.surface = DayScheduleViewController.mockedEntriesFor(dayId: id)
        return vc
    }
}

extension DayNavigationViewController: UIPageViewControllerDelegate {
    func pageViewController(_ pageViewController: UIPageViewController,
                            didFinishAnimating finished: Bool,
                            previousViewControllers: [UIViewController],
                            transitionCompleted completed: Bool) {
        updateTitleFor(vc: pageViewController.viewControllers?.first as! DayScheduleViewController)
    }

    fileprivate func updateTitleFor(vc: DayScheduleViewController) {
        titleView.titleLabel.text = vc.surface?.dateDescription
        titleView.subtitleLabel.text = vc.surface?.weekdayDescription
        titleView.setNeedsLayout()
    }
}
