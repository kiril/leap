//
//  Fetchable.swift
//  Leap
//
//  Created by Kiril Savino on 3/28/17.
//  Copyright © 2017 Single Leap, Inc. All rights reserved.
//

import Foundation
import RealmSwift

protocol Fetchable {
    var id: String { get }
    var isReal: Bool { get }
    static func by(id: String) -> LeapModel?
    static func by(_ key: String, is string: String) -> LeapModel?
    static func by(_ key: String, is int: Int) -> LeapModel?
}


extension Fetchable where Self:LeapModel {
    var isReal: Bool {
        return true
        //return Realm.user().objects(Self.self).filter("id = %@", self.id).count > 0 || Realm.temp().objects(Self.self).filter("id = %@", self.id).count == 0
    }

    static func by(id: String) -> Self? {
        return Realm.user().objects(Self.self).filter("id = %@", id).first// ?? Realm.temp().objects(Self.self).filter("id = %@", id).first
    }

    static func by(_ key: String, is string: String) -> Self? {
        return Realm.user().objects(Self.self).filter("\(key) = %@", string).first
    }

    static func by(_ key: String, is int: Int) -> Self? {
        return Realm.user().objects(Self.self).filter("\(key) = %d", int).first
    }
}

extension LeapModel: Fetchable {
}
