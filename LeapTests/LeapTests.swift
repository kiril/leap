//
//  LeapTests.swift
//  LeapTests
//
//  Created by Kiril Savino on 12/9/16.
//  Copyright © 2016 Kiril Savino. All rights reserved.
//

import XCTest
@testable import Leap

class LeapTests: XCTestCase {
    func testSwift() {

        switch Int(-2) {
        case Int.min..<0:
            print("sanity is sane for -1 raw")

        case Int.min...(-1):
            print("sanity is slightly sane for -1 raw")

        case -1000000..<0:
            print("sanity is at least possibly rationally flawed and mendable for -1 raw")

        case -1000000...(-1):
            print("sanity is broken but we can survive for -1 raw")

        default:
            fatalError("The world is fucked")
        }



        switch Double(-2) {
        case -100000000.0..<Double(0.0):
            print("The world is sane")

        default:
            fatalError("The world is not sane")
        }
    }
    
}
