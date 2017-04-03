//
//  WeekNavigationViewController.swift
//  Leap
//
//  Created by Chris Ricca on 3/29/17.
//  Copyright © 2017 Single Leap, Inc. All rights reserved.
//

import UIKit

class WeekNavigationViewController: UIViewController, StoryboardLoadable {

    var titleView: DayScheduleTitleView!

    @IBOutlet weak var weekNavContainerView: UIView!
    @IBOutlet weak var navigationBarUnderlay: UIView!
    @IBOutlet weak var backgroundView: UIView!
    @IBOutlet weak var bottomBorder: UIView!
    @IBOutlet weak var previousNavArrow: UILabel!
    @IBOutlet weak var nextNavArrow: UILabel!
    @IBOutlet weak var weekOverviewContainerView: UIView!

    var selectedDayId: String = String(Calendar.current.today.id)

    var weekOverviewPageViewController: UIPageViewController!
    private lazy var weekOverviewPageViewDataSource = WeekOverviewPageViewDataSource()
    override func viewDidLoad() {
        super.viewDidLoad()

        setupViews()
        setupNavigationBar()
        setupWeekOverviewPageViewController()
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
                                                              navigationOrientation: .horizontal,
                                                              options: nil)

        weekOverviewPageViewController.dataSource = weekOverviewPageViewDataSource
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
        titleView.subtitleLabel.text = ""
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
                            didFinishAnimating finished: Bool, previousViewControllers: [UIViewController], transitionCompleted completed: Bool) {
        updateTitleFor(vc: pageViewController.viewControllers?.first as! WeekOverviewViewController)
    }

    fileprivate func updateTitleFor(vc: WeekOverviewViewController) {
        titleView.titleLabel.text = vc.surface?.titleForWeek
        titleView.setNeedsLayout()
    }
}
