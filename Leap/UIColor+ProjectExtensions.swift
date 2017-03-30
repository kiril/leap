//
//  UIColor+ProjectExtensions.swift
//  Leap
//
//  Created by Chris Ricca on 3/28/17.
//  Copyright © 2017 Single Leap, Inc. All rights reserved.
//

import UIKit

extension UIColor {
    public convenience init(r red: Int, g green: Int, b blue: Int) {
        self.init(red: CGFloat(red) / CGFloat(255.0),
                  green: CGFloat(green) / CGFloat(255),
                  blue: CGFloat(blue) / CGFloat(255),
                  alpha: 1)
    }
}

extension UIColor {

    // These shouldn't have to be public but I keep getting intermittant Xcode failures (they go away when I actually build the project). SHould test with later version of xcode and remove if possible.

    public static var projectLightBackgroundGray: UIColor {
        return UIColor(r: 246,
                       g: 246,
                       b: 246)
    }

    public static var projectLightGray: UIColor {
        return UIColor(r: 189,
                       g: 189,
                       b: 189)
    }

    public static var projectDarkGray: UIColor {
        return UIColor(r: 112,
                       g: 112,
                       b: 112)
    }

    public static var projectDarkerGray: UIColor {
        return UIColor(r: 84,
                       g: 84,
                       b: 84)
    }

    public static var navigationBarSeparatorColor: UIColor {
        return UIColor(r: 178,
                       g: 178,
                       b: 178)
    }
}
