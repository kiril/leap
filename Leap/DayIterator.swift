//
//  DayIterator.swift
//  Leap
//
//  Created by Kiril Savino on 5/18/17.
//  Copyright © 2017 Single Leap, Inc. All rights reserved.
//

import Foundation

class DayIterator: IteratorProtocol {
    private let traversal: DayTraversal
    private let start: Date
    private var current: Date?
    private var count: Int = 0
    private let max: Int

    init(using traversal: DayTraversal, startingWith date: Date, max: Int = 0) {
        self.traversal = traversal
        self.start = date
        self.max = max
    }

    func next() -> Date? {
        if count == 0 {
            current = start
            count += 1
            return current

        } else if max > 0 && count >= max {
            return nil
        }

        guard let current = self.current else { return nil }
        self.current = traversal.day(after: current)
        count += 1
        return self.current
    }

    func reset() {
        count = 0
    }
}
