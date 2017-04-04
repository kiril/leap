//
//  WeekNavigationViewController.swift
//  Leap
//
//  Created by Chris Ricca on 3/29/17.
//  Copyright © 2017 Single Leap, Inc. All rights reserved.
//

import UIKit

protocol WeekNavigationViewControllerDelegate: class {
    func didSelectDay(dayId: String, on: WeekNavigationViewController)
}

class WeekNavigationViewController: UIViewController, StoryboardLoadable {

    var titleView: DayScheduleTitleView!
    weak var delegate: WeekNavigationViewControllerDelegate?

    @IBOutlet weak var weekNavContainerView: UIView!
    @IBOutlet weak var navigationBarUnderlay: UIView!
    @IBOutlet weak var backgroundView: UIView!
    @IBOutlet weak var bottomBorder: UIView!
    @IBOutlet weak var previousNavArrow: UILabel!
    @IBOutlet weak var nextNavArrow: UILabel!
    @IBOutlet weak var weekOverviewContainerView: UIView!

    var selectedDayId: String = String(Calendar.current.today.id)

    var weekOverviewPageViewController: UIPageViewController!

    override func viewDidLoad() {
        super.viewDidLoad()

        setupViews()
        setupNavigationBar()
        setupWeekOverviewPageViewController()
        setupArrowNavigation()
    }

    private func setupArrowNavigation() {
        setupArrow(label: nextNavArrow)
        setupArrow(label: previousNavArrow)
    }

    private func setupArrow(label: UILabel) {
        let tapGesture = UITapGestureRecognizer(target: self,
                                                action: #selector(didTapArrow))
        label.isUserInteractionEnabled = true
        label.addGestureRecognizer(tapGesture)
    }

    @objc private func didTapArrow(sender: UITapGestureRecognizer) {
        guard let arrow = sender.view else { return }
        let direction: UIPageViewControllerNavigationDirection = (arrow == nextNavArrow) ? .forward : .reverse
        weekOverviewPageViewController.turnPage(direction: direction)
    }

    private func setupViews() {
        let tap = UITapGestureRecognizer(target: self, action: #selector(didTapBackgroundView))
        backgroundView.addGestureRecognizer(tap)

        weekNavContainerView.backgroundColor = UIColor.projectLightBackgroundGray
        navigationBarUnderlay.backgroundColor = UIColor.projectLightBackgroundGray

        previousNavArrow.textColor = UIColor.projectDarkerGray
        nextNavArrow.textColor = UIColor.projectDarkerGray
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
    }

    private func setupWeekOverviewPageViewController() {
        weekOverviewPageViewController = UIPageViewController(transitionStyle: .scroll,
                                                              navigationOrientation: .vertical,
                                                              options: nil)

        weekOverviewPageViewController.dataSource = self
        weekOverviewPageViewController.delegate = self
        
        addChildViewController(weekOverviewPageViewController)
//        weekOverviewPageViewController.view.frame = CGRect.zero
        weekOverviewContainerView.addSubview(weekOverviewPageViewController.view)

        weekOverviewPageViewController.view.leftAnchor.constraint(equalTo: weekOverviewContainerView.leftAnchor).isActive = true
        weekOverviewPageViewController.view.rightAnchor.constraint(equalTo: weekOverviewContainerView.rightAnchor).isActive = true
        weekOverviewPageViewController.view.topAnchor.constraint(equalTo: weekOverviewContainerView.topAnchor).isActive = true
        weekOverviewPageViewController.view.bottomAnchor.constraint(equalTo: weekOverviewContainerView.bottomAnchor).isActive = true

        weekOverviewPageViewController.didMove(toParentViewController: self)

        weekOverviewPageViewController.view.translatesAutoresizingMaskIntoConstraints = false // HELPS
        weekOverviewPageViewController.view.backgroundColor = UIColor.clear

        let initialWeek = WeekOverviewSurface(containingDayId: selectedDayId)
        let initialWeekVC = WeekOverviewViewController.loadFromStoryboard()
        initialWeekVC.surface = initialWeek
        initialWeekVC.delegate = self
        weekOverviewPageViewController.setViewControllers([initialWeekVC],
                                                          direction: .forward,
                                                          animated: false, completion: nil)

        updateTitleFor(vc: initialWeekVC)
    }

    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()

//        weekOverviewPageViewController.view.frame = weekDisplayContainerView.bounds
    }

    private func setupNavigationBar() {
        navigationController?.navigationBar.setBackgroundImage(UIImage(), for: .default)
        navigationController?.navigationBar.shadowImage = UIImage()
        navigationController?.navigationBar.backgroundColor = UIColor.projectLightBackgroundGray
        bottomBorder.backgroundColor = UIColor.navigationBarSeparatorColor

        setupNavigation()
    }

    private func setupNavigation() {
        let titleNib = UINib(nibName: "DayScheduleTitleView", bundle: nil)
        titleView = titleNib.instantiate(withOwner: nil, options: nil).first as! DayScheduleTitleView
        titleView.subtitleLabel.text = "Hello"
        titleView.titleLabel.text = "Dec 3 - Dec 9, 2017"

        let arrowNib = UINib(nibName: "NavigationToggleArrowView", bundle: nil)
        let arrowView = arrowNib.instantiate(withOwner: nil, options: nil).first as! NavigationToggleArrowView
        arrowView.direction = .up

        navigationItem.leftBarButtonItems = [
            barButtonItemFor(navView: arrowView),
            barButtonItemFor(navView: titleView)
        ]
    }

    private func barButtonItemFor(navView view: UIView) -> UIBarButtonItem {
        view.translatesAutoresizingMaskIntoConstraints = false
        let tap = UITapGestureRecognizer(target: self, action: #selector(didTapBackgroundView))
        view.addGestureRecognizer(tap)

        return UIBarButtonItem(customView: view)
    }

    @objc private func didTapBackgroundView() {
        self.dismiss(animated: true, completion: nil)
    }
}

extension WeekNavigationViewController: UIPageViewControllerDelegate {
    func pageViewController(_ pageViewController: UIPageViewController,
                            didFinishAnimating finished: Bool,
                            previousViewControllers: [UIViewController],
                            transitionCompleted completed: Bool) {
        updateTitleFor(vc: pageViewController.viewControllers?.first as! WeekOverviewViewController)
    }

    fileprivate func updateTitleFor(vc: WeekOverviewViewController) {
        titleView.titleLabel.text = vc.surface?.titleForWeek
        titleView.subtitleLabel.text = vc.surface?.weekRelativeDescription
        titleView.setNeedsLayout()
    }
}

extension WeekNavigationViewController: UIPageViewControllerDataSource {
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
        vc.delegate = self
        return vc
    }
}

extension WeekNavigationViewController: WeekOverviewViewControllerDelegate {
    func didSelectDay(dayId: String, on: WeekOverviewViewController) {
        delegate?.didSelectDay(dayId: dayId,
                               on: self)
    }
}
