//
//  GregorianDayTests.swift
//  Leap
//
//  Created by Chris Ricca on 4/20/17.
//  Copyright © 2017 Single Leap, Inc. All rights reserved.
//

import XCTest
@testable import Leap

class TimeRangeTests: XCTestCase {

    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }

    func testExcludingRanges() {
        let originalRange = TimeRange(start:    Date(timeIntervalSinceReferenceDate: 10),
                                      end:      Date(timeIntervalSinceReferenceDate: 20))!

        let beforeRange = TimeRange(start:  Date(timeIntervalSinceReferenceDate: 2),
                                    end:    Date(timeIntervalSinceReferenceDate: 5))!

        let exludingBefore = originalRange.timeRangesByExcluding(timeRange: beforeRange)
        XCTAssertEqual(1, exludingBefore.count)
        XCTAssertEqual(10, exludingBefore.first!.start.timeIntervalSinceReferenceDate)
        XCTAssertEqual(20, exludingBefore.first!.end.timeIntervalSinceReferenceDate)


        let beforeTouchingRange = TimeRange(start:  Date(timeIntervalSinceReferenceDate: 2),
                                            end:    Date(timeIntervalSinceReferenceDate: 10))!

        let exludingBeforeTouching = originalRange.timeRangesByExcluding(timeRange: beforeTouchingRange)
        XCTAssertEqual(1, exludingBeforeTouching.count)
        XCTAssertEqual(10, exludingBeforeTouching.first!.start.timeIntervalSinceReferenceDate)
        XCTAssertEqual(20, exludingBeforeTouching.first!.end.timeIntervalSinceReferenceDate)


        let beforeInsideRange = TimeRange(start:  Date(timeIntervalSinceReferenceDate: 2),
                                          end:    Date(timeIntervalSinceReferenceDate: 15))!
        let exludingBeforeInside = originalRange.timeRangesByExcluding(timeRange: beforeInsideRange)
        XCTAssertEqual(1, exludingBeforeInside.count)
        XCTAssertEqual(15, exludingBeforeInside.first!.start.timeIntervalSinceReferenceDate)
        XCTAssertEqual(20, exludingBeforeInside.first!.end.timeIntervalSinceReferenceDate)


        let insideRange = TimeRange(start:  Date(timeIntervalSinceReferenceDate: 12),
                                          end:    Date(timeIntervalSinceReferenceDate: 18))!
        let exludingInside = originalRange.timeRangesByExcluding(timeRange: insideRange)
        XCTAssertEqual(2, exludingInside.count)
        XCTAssertEqual(10, exludingInside.first!.start.timeIntervalSinceReferenceDate)
        XCTAssertEqual(12, exludingInside.first!.end.timeIntervalSinceReferenceDate)
        XCTAssertEqual(18, exludingInside[1].start.timeIntervalSinceReferenceDate)
        XCTAssertEqual(20, exludingInside[1].end.timeIntervalSinceReferenceDate)


        let duringTouchingEndRange = TimeRange(start:  Date(timeIntervalSinceReferenceDate: 12),
                                               end:    Date(timeIntervalSinceReferenceDate: 20))!
        let exludingDuringTouchingEnd = originalRange.timeRangesByExcluding(timeRange: duringTouchingEndRange)
        XCTAssertEqual(1, exludingDuringTouchingEnd.count)
        XCTAssertEqual(10, exludingDuringTouchingEnd.first!.start.timeIntervalSinceReferenceDate)
        XCTAssertEqual(12, exludingDuringTouchingEnd.first!.end.timeIntervalSinceReferenceDate)

        // duringEndingAfter


        let duringEndingAfterRange = TimeRange(start:  Date(timeIntervalSinceReferenceDate: 12),
                                               end:    Date(timeIntervalSinceReferenceDate: 22))!
        let exludingDuringEndingAfter = originalRange.timeRangesByExcluding(timeRange: duringEndingAfterRange)
        XCTAssertEqual(1, exludingDuringEndingAfter.count)
        XCTAssertEqual(10, exludingDuringEndingAfter.first!.start.timeIntervalSinceReferenceDate)
        XCTAssertEqual(12, exludingDuringEndingAfter.first!.end.timeIntervalSinceReferenceDate)


        // after

        let afterRange = TimeRange(start:  Date(timeIntervalSinceReferenceDate: 21),
                                   end:    Date(timeIntervalSinceReferenceDate: 25))!
        let excludingAfter = originalRange.timeRangesByExcluding(timeRange: afterRange)
        XCTAssertEqual(1, excludingAfter.count)
        XCTAssertEqual(10, excludingAfter.first!.start.timeIntervalSinceReferenceDate)
        XCTAssertEqual(20, excludingAfter.first!.end.timeIntervalSinceReferenceDate)


        // total overlap

        let encompassingRange = TimeRange(start:  Date(timeIntervalSinceReferenceDate: 8),
                                          end:    Date(timeIntervalSinceReferenceDate: 22))!
        let excludingEncompassing = originalRange.timeRangesByExcluding(timeRange: encompassingRange)
        XCTAssertEqual(0, excludingEncompassing.count)


        // same

        let sameRange = TimeRange(start:  Date(timeIntervalSinceReferenceDate: 10),
                                  end:    Date(timeIntervalSinceReferenceDate: 20))!
        let excludingSame = originalRange.timeRangesByExcluding(timeRange: sameRange)
        XCTAssertEqual(0, excludingSame.count)
    }

    func testExcludingFromArray() {
        let originalRange1 = TimeRange(start:    Date(timeIntervalSinceReferenceDate: 2),
                                       end:      Date(timeIntervalSinceReferenceDate: 4))!

        let originalRange2 = TimeRange(start:    Date(timeIntervalSinceReferenceDate: 10),
                                       end:      Date(timeIntervalSinceReferenceDate: 14))!

        let originalRange3 = TimeRange(start:    Date(timeIntervalSinceReferenceDate: 18),
                                       end:      Date(timeIntervalSinceReferenceDate: 20))!

        let originalRange4 = TimeRange(start:    Date(timeIntervalSinceReferenceDate: 22),
                                       end:      Date(timeIntervalSinceReferenceDate: 25))!

        let originalRanges = [originalRange1, originalRange2, originalRange3, originalRange4]

        let excludingRange = TimeRange(start:    Date(timeIntervalSinceReferenceDate: 12),
                                       end:      Date(timeIntervalSinceReferenceDate: 19))!

        let resultingRanges = originalRanges.timeRangesByExcluding(timeRange: excludingRange)
        XCTAssertEqual(4, resultingRanges.count)

        XCTAssertEqual(2, resultingRanges[0].start.timeIntervalSinceReferenceDate)
        XCTAssertEqual(4, resultingRanges[0].end.timeIntervalSinceReferenceDate)

        XCTAssertEqual(10, resultingRanges[1].start.timeIntervalSinceReferenceDate)
        XCTAssertEqual(12, resultingRanges[1].end.timeIntervalSinceReferenceDate)

        XCTAssertEqual(19, resultingRanges[2].start.timeIntervalSinceReferenceDate)
        XCTAssertEqual(20, resultingRanges[2].end.timeIntervalSinceReferenceDate)

        XCTAssertEqual(22, resultingRanges[3].start.timeIntervalSinceReferenceDate)
        XCTAssertEqual(25, resultingRanges[3].end.timeIntervalSinceReferenceDate)
    }

    func testDuration() {
        let firstRange = TimeRange(start:    Date(timeIntervalSinceReferenceDate: 10),
                                   end:      Date(timeIntervalSinceReferenceDate: 20))!

        XCTAssertEqual(10.0, firstRange.durationInSeconds)

        let secondRange = TimeRange(start:    Date(timeIntervalSinceReferenceDate: 15),
                                    end:      Date(timeIntervalSinceReferenceDate: 30))!


        XCTAssertEqual(15.0, secondRange.durationInSeconds)

        let totalRange = [firstRange, secondRange]

        XCTAssertEqual(25.0, totalRange.combinedDurationInSeconds)
    }

    func testPerformanceExample() {
        // This is an example of a performance test case.
        self.measure {
            // Put the code you want to measure the time of here.
        }
    }
    
}
