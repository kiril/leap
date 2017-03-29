//
//  UIColor+ProjectExtensions.swift
//  Leap
//
//  Created by Chris Ricca on 3/28/17.
//  Copyright © 2017 Single Leap, Inc. All rights reserved.
//

import UIKit

extension UIColor {
    convenience init(r red: Int, g green: Int, b blue: Int) {
        self.init(red: CGFloat(red) / CGFloat(255.0),
                  green: CGFloat(green) / CGFloat(255),
                  blue: CGFloat(blue) / CGFloat(255),
                  alpha: 1)
    }
}
