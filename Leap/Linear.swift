//
//  Linear.swift
//  Leap
//
//  Created by Kiril Savino on 5/4/17.
//  Copyright © 2017 Single Leap, Inc. All rights reserved.
//

import Foundation

protocol Linear {
    var duration: TimeInterval { get }
    var secondsLong: Int { get }
    var minutesLong: Int { get }
    func formatDuration() -> String?
}
