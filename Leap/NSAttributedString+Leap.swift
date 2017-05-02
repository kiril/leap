//
//  NSAttributedString+Leap.swift
//  Leap
//
//  Created by Kiril Savino on 5/2/17.
//  Copyright © 2017 Single Leap, Inc. All rights reserved.
//

import Foundation
import UIKit

extension NSMutableAttributedString {
    func append(string: String, attributes: [String: Any]) {
        let attributed = NSMutableAttributedString(string: string)
        let range = NSRange(location: 0, length: string.utf16.count)
        for (attribute, value) in attributes {
            attributed.addAttribute(attribute, value: value, range: range)
        }
        append(attributed)
    }
}

extension NSAttributedString {
    func appending(string: String, attributes: [String: Any]) -> NSAttributedString {
        let mutable = NSMutableAttributedString(attributedString: self)
        mutable.append(string: string, attributes: attributes)
        return mutable
    }
}
