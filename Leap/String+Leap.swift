//
//  String+Leap.swift
//  Leap
//
//  Created by Kiril Savino on 4/27/17.
//  Copyright © 2017 Single Leap, Inc. All rights reserved.
//

import Foundation

public enum Truncation {
    case beginning
    case middle
    case end
}

extension String {
    static let fa_sticky_open = ""
    static let fa_sticky_closed = ""
    static let fa_arrow_spanning = ""

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

    public func truncate(to maxChars: Int, in truncation: Truncation) -> String {
        let length = self.utf16.count
        let ellipsis = "\u{2026}"
        guard length > maxChars else { return self }

        switch truncation {
        case .beginning:
            let offset = length - maxChars + 1
            let tail = self.substring(from: index(startIndex, offsetBy: IndexDistance(offset)))
            return "\(ellipsis)\(tail)"

        case .middle:
            let middle = length / 2
            let toElide = (length - maxChars) + 1
            let elideLeft = toElide / 2
            let elideRight = toElide / 2
            let leftStop = middle - elideLeft
            let rightStart = middle + elideRight
            let head = substring(to: index(startIndex, offsetBy: IndexDistance(leftStop)))
            let tail = substring(from: index(startIndex, offsetBy: IndexDistance(rightStart)))
            return "\(head)\(ellipsis)\(tail)"

        case .end:
            let offset = length - maxChars + 1
            let head = self.substring(to: index(endIndex, offsetBy: IndexDistance(-offset)))
            return "\(head)\(ellipsis)"
        }
    }
}
