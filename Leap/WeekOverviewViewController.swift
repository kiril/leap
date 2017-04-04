//
//  WeekOverviewViewController.swift
//  Leap
//
//  Created by Chris Ricca on 4/1/17.
//  Copyright © 2017 Single Leap, Inc. All rights reserved.
//

import UIKit

protocol WeekOverviewViewControllerDelegate: class {
    func didSelectDay(dayId: String, on: WeekOverviewViewController)
}

class WeekOverviewViewController: UIViewController, StoryboardLoadable {

    weak var delegate: WeekOverviewViewControllerDelegate?

    @IBOutlet var dayButtons: [UIButton]!

    var surface: WeekOverviewSurface?

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        setupDays()
    }

    private func setupDays() {
        for (index, button) in dayButtons.enumerated() {
            guard let day = surface?.days[index] else { continue }
            let title = day.overviewDescription
            button.setTitle(title, for: .normal)
            button.addTarget(self,
                             action: #selector(didTapButton(sender:)),
                             for: .touchUpInside)

            switch day.happensIn {
            case .current:
                break
            case .future:
                button.setTitleColor(UIColor.black, for: .normal)
            case .past:
                button.setTitleColor(UIColor.gray, for: .normal)
            }
        }
    }

    @objc func didTapButton(sender: UIButton) {
        for (index, button) in dayButtons.enumerated() {
            if sender == button {
                guard let id = surface?.days[index].id else { return }
                delegate?.didSelectDay(dayId: id, on: self)
                return
            }
        }
    }
}
