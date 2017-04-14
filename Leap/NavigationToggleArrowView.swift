//
//  NavigationToggleArrowView.swift
//  Leap
//
//  Created by Chris Ricca on 3/29/17.
//  Copyright © 2017 Single Leap, Inc. All rights reserved.
//

import UIKit

enum NavigationToggleDirection {
    case up, down
}
class NavigationToggleArrowView: UIView {

    @IBOutlet weak var downArrowLabel: UILabel!
    @IBOutlet weak var upArrowLabel: UILabel!

    var direction = NavigationToggleDirection.up {
        didSet {
            updateArrowDisplay()
        }
    }

    private func updateArrowDisplay() {
        downArrowLabel.isHidden = (direction != .down)
        upArrowLabel.isHidden = (direction != .up)
    }

    override func awakeFromNib() {
        setup()
    }

    private func setup() {
        updateArrowDisplay()
        downArrowLabel.textColor = UIColor.projectDarkerGray
        upArrowLabel.textColor = UIColor.projectDarkerGray
    }
}
