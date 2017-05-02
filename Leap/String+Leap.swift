//
//  String+Leap.swift
//  Leap
//
//  Created by Kiril Savino on 4/27/17.
//  Copyright © 2017 Single Leap, Inc. All rights reserved.
//

import Foundation

extension String {
    static let addressPattern = "^\\d{1,4}[a-zA-Z]*\\s+\\w|\\s+\\d{5}(-\\d{4})?\\s*$|^(\\w+\\b\\s*)+,\\s+\\d{1,4}[a-zA-Z]*\\s+\\w.*(\\w+\\b\\s*)+,\\s+\\w{2}\\b"
    static let addressRegexp = try! NSRegularExpression(pattern: String.addressPattern, options: .caseInsensitive)

    func matches(pattern: String) throws -> Bool {
        let regex = try NSRegularExpression(pattern: pattern, options: .caseInsensitive)
        return regex.matches(in: self, options: .anchored, range: NSMakeRange(0,  self.characters.count)).count > 0
    }

    func matches(regex: NSRegularExpression) -> Bool {
        return regex.matches(in: self, options: .anchored, range: NSMakeRange(0,  self.characters.count)).count > 0
    }

    var looksLikeAnAddress: Bool {
        return self.matches(regex: String.addressRegexp)
    }

    var hasNonWhitespaceCharacters: Bool {
        if self.isEmpty {
            return false
        }
        for c in self.characters {
            switch c {
            case "\n", "\r", " ", "\t":
                continue
            default:
                return true
            }
        }
        return false
    }
}
