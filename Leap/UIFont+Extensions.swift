//
//  UIFont+Extensions.swift
//  Leap
//
//  Created by Chris Ricca on 4/12/17.
//  Copyright © 2017 Single Leap, Inc. All rights reserved.
//

import UIKit

extension UIFont {

    var toBoldSystemVersion: UIFont {
        return toSystemVersion(withBold: true)
    }

    var toSystemVersion: UIFont {
        return toSystemVersion(withBold: false)
    }

    func toSystemVersion(withBold bold: Bool = false) -> UIFont {
        let size = pointSize

        if bold {
            return UIFont.boldSystemFont(ofSize: size)
        } else {
            return UIFont.systemFont(ofSize: size)
        }
    }

}
