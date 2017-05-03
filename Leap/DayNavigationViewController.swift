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

    @IBOutlet weak var hiddenEventsButton: UIButton!

    fileprivate var currentlySelectedDayScheduleVC: DayScheduleViewController? {
        return daySchedulePageViewController.viewControllers?.first as? DayScheduleViewController
    }
    fileprivate var currentlySelectedDay: DaySurface? {
        return currentlySelectedDayScheduleVC?.surface.day
    }

    var daySchedulePageViewController: UIPageViewController!

    override func viewDidLoad() {
        super.viewDidLoad()

        setupNavigation()
        setupPageViewController()
        setupHiddenEventsButton()
        // Do any additional setup after loading the view.
    }

    private func setupPageViewController() {
        daySchedulePageViewController = UIPageViewController(transitionStyle: .scroll,
                                                             navigationOrientation: .horizontal,
                                                             options: nil)

        daySchedulePageViewController.dataSource = self
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

        let dayVC = dayScheduleViewController(forDayId: Calendar.current.today.id)
        daySchedulePageViewController.setViewControllers([dayVC],
                                                          direction: .forward,
                                                          animated: false, completion: nil)

        updateLabelsFor(vc: dayVC)
    }

    fileprivate func dayScheduleViewController(forDayId dayId: Int) -> DayScheduleViewController {
        let daySchedule = DayScheduleSurface.load(dayId: dayId)
        let dayVC = DayScheduleViewController.loadFromStoryboard()
        dayVC.surface = daySchedule
        //dayVC.navigationItem.title = daySchedule.day.shortDateString
        daySchedule.register(observer: dayVC)
        daySchedule.register(observer: self)
        return dayVC
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

    private func setupHiddenEventsButton() {
        let cornerRadius: CGFloat = 10.0

        let blur = UIVisualEffectView(effect: UIBlurEffect(style: .regular))
        blur.isUserInteractionEnabled = false
        blur.frame = hiddenEventsButton.bounds

        hiddenEventsButton.insertSubview(blur, at: 0)
        hiddenEventsButton.layer.cornerRadius = cornerRadius
        hiddenEventsButton.layer.masksToBounds = true
        hiddenEventsButton.layer.borderColor = UIColor.projectPurple.cgColor
        hiddenEventsButton.layer.borderWidth = 0.5
        hiddenEventsButton.addTarget(self,
                                     action: #selector(toggleHideEvents),
                                     for: .touchUpInside)

    }

    @objc func toggleHideEvents() {
        guard let vc = daySchedulePageViewController.viewControllers?.first as? DayScheduleViewController else { return }

        vc.surface.toggleHiddenEvents()
        updateLabelsFor(vc: vc)
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


    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    func navigateToDay(dayId: String?) {
        guard   let currentId = currentlySelectedDay?.intId,
            let dayId = dayId,
            dayId != String(currentId) else {
                return
        }

        let direction: UIPageViewControllerNavigationDirection = (Int(dayId)! > currentId) ? .forward : .reverse


        let dayVC = dayScheduleViewController(forDayId: Int(dayId)!)
        daySchedulePageViewController.setViewControllers([dayVC],
                                                         direction: direction,
                                                         animated: true) {[weak self] _ in
            self?.updateLabelsFor(vc: dayVC)
        }
    }
}

extension DayNavigationViewController: WeekNavigationViewControllerDelegate {
    func didSelectDay(dayId: String?, on viewController: WeekNavigationViewController) {
        navigateToDay(dayId: dayId)
        dismiss(animated: true)
    }
}

extension DayNavigationViewController: UIPageViewControllerDataSource {
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
        guard let id = Int(surface.id) else { return nil }
        return dayScheduleViewController(forDayId: id)
    }
}

extension DayNavigationViewController: UIPageViewControllerDelegate {
    func pageViewController(_ pageViewController: UIPageViewController,
                            didFinishAnimating finished: Bool,
                            previousViewControllers: [UIViewController],
                            transitionCompleted completed: Bool) {
        updateLabelsFor(vc: pageViewController.viewControllers?.first as! DayScheduleViewController)
    }

    fileprivate func updateLabelsFor(vc: DayScheduleViewController) {
        titleView.titleLabel.text = vc.surface?.dateDescription
        titleView.subtitleLabel.text = vc.surface?.weekdayDescription

        if let perspective = currentlySelectedDay?.happensIn {
            switch perspective {
            case .current:
                titleView.style = .bold
            case .future:
                titleView.style = .normal
            case .past:
                titleView.style = .light
            }
        }

        titleView.setNeedsLayout()

        hiddenEventsButton.setTitle(vc.surface?.textForHiddenButton, for: .normal)
        hiddenEventsButton.isEnabled = vc.surface.enableHideableEventsButton


        navigationItem.backBarButtonItem = UIBarButtonItem(title: vc.surface.day.shortDateString, style: .plain, target: nil, action: nil)
    }
}

extension DayNavigationViewController: SelectedTabTappable {
    func selectedTabWasTapped(on tabBarController: MainTabBarController) {
        navigateToDay(dayId: String(Calendar.current.today.id))
        dismiss(animated: true)
    }
}

extension DayNavigationViewController: SourceIdentifiable {
    var sourceId: String { return "DayNavigationViewController" }
}


extension DayNavigationViewController: SurfaceObserver {
    func surfaceDidChange(_ surface: Surface) {
        guard let   vc = currentlySelectedDayScheduleVC,
                    vc.surface == surface else { return }

        // update hidden events button if necessary
        updateLabelsFor(vc: vc)
    }
}
