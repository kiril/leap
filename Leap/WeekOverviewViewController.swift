//
//  WeekOverviewViewController.swift
//  Leap
//
//  Created by Chris Ricca on 3/29/17.
//  Copyright © 2017 Single Leap, Inc. All rights reserved.
//

import UIKit

class WeekOverviewViewController: UIViewController, StoryboardLoadable {

    @IBOutlet weak var navigationBarUnderlay: UIView!
    @IBOutlet weak var backgroundView: UIView!
    @IBOutlet weak var weekDisplayContainerView: UIView!
    @IBOutlet weak var bottomBorder: UIView!
    @IBOutlet weak var previousNavArrow: UILabel!
    @IBOutlet weak var nextNavArrow: UILabel!


    override func viewDidLoad() {
        super.viewDidLoad()

        setupViews()
        setupNavigationBar()
    }

    private func setupViews() {
        let tap = UITapGestureRecognizer(target: self, action: #selector(didTapBackgroundView))
        backgroundView.addGestureRecognizer(tap)

        weekDisplayContainerView.backgroundColor = UIColor.projectLightBackgroundGray
        navigationBarUnderlay.backgroundColor = UIColor.projectLightBackgroundGray

        previousNavArrow.textColor = UIColor.projectDarkerGray
        nextNavArrow.textColor = UIColor.projectDarkerGray
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
        let titleView = titleNib.instantiate(withOwner: nil, options: nil).first as! DayScheduleTitleView
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
