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

    @IBOutlet weak var arrowLabel: UILabel!

    var direction = NavigationToggleDirection.up {
        didSet {
            arrowLabel.text = (direction == .up) ? upString : downString
        }
    }

    private let downString = ""
    private let upString = ""

    override func awakeFromNib() {
        setup()
    }

    private func setup() {
        arrowLabel.textColor = UIColor.projectDarkerGray
    }
}
