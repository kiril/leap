//
//  StringTests.swift
//  Leap
//
//  Created by Kiril Savino on 5/1/17.
//  Copyright © 2017 Single Leap, Inc. All rights reserved.
//

import XCTest

class StringTests: XCTestCase {
    
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }

    func testTruncate() {

        let ellipsis = "\u{2026}"
        XCTAssertEqual("foobar".truncate(to: 3, in: .end), "fo\(ellipsis)")
        XCTAssertEqual("foobar".truncate(to: 3, in: .beginning), "\(ellipsis)ar")
        XCTAssertEqual("foobar".truncate(to: 3, in: .middle), "f\(ellipsis)r")
    }
    
}
