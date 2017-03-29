//
//  NavigationToggleArrowView.swift
//  Leap
//
//  Created by Chris Ricca on 3/29/17.
//  Copyright © 2017 Single Leap, Inc. All rights reserved.
//

import UIKit

class NavigationToggleArrowView: UIView {

    @IBOutlet weak var arrowLabel: UILabel!

    override func awakeFromNib() {
        setup()
    }

    private func setup() {
        arrowLabel.textColor = UIColor.projectDarkerGray
    }
}
