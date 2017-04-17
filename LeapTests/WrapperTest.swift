//
//  WrapperTest.swift
//  Leap
//
//  Created by Kiril Savino on 4/17/17.
//  Copyright © 2017 Single Leap, Inc. All rights reserved.
//

import XCTest

@testable import Leap

class WrapperTest: XCTestCase {
    
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func testIntWrapper() {
        let a = IntWrapper.of(4)
        XCTAssertEqual(a.raw, 4)
    }
    
}
