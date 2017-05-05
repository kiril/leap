//
//  UIView+Leap.swift
//  Leap
//
//  Created by Kiril Savino on 5/5/17.
//  Copyright © 2017 Single Leap, Inc. All rights reserved.
//

import Foundation
import UIKit

extension UIView {
    var isVisible: Bool {
        get { return !isHidden }
        set { isHidden = !newValue }
    }
}
