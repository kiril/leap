//
//  String+Leap.swift
//  Leap
//
//  Created by Kiril Savino on 4/27/17.
//  Copyright © 2017 Single Leap, Inc. All rights reserved.
//

import Foundation

extension String {
    func matches(regex: String) throws -> Bool {
        let re = try NSRegularExpression(pattern: regex, options: .caseInsensitive)
        return re.matches(in: self, options: .anchored, range: NSMakeRange(0,  self.characters.count)).count > 0
    }

    var looksLikeAnAddress: Bool {
        return try! self.matches(regex: "^\\d{1,4}[a-zA-Z]*\\s+\\w|\\s+\\d{5}(-\\d{4})?$")
    }
}
