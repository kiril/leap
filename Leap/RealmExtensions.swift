//
//  RealmExtensions.swift
//  Leap
//
//  Created by Chris Ricca on 4/13/17.
//  Copyright © 2017 Single Leap, Inc. All rights reserved.
//

import RealmSwift

extension Realm {
    func safeWrite(block: ()->()) throws {
        let wasInWriteBlock = isInWriteTransaction
        if !wasInWriteBlock { beginWrite() }
        block()
        if !wasInWriteBlock { try commitWrite() }
    }
}
