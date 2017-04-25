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
}


extension Fetchable where Self:LeapModel {
    var isReal: Bool {
        return true
        //return Realm.user().objects(Self.self).filter("id = %@", self.id).count > 0 || Realm.temp().objects(Self.self).filter("id = %@", self.id).count == 0
    }

    static func by(id: String) -> Self? {
        return Realm.user().objects(Self.self).filter("id = %@", id).first// ?? Realm.temp().objects(Self.self).filter("id = %@", id).first
    }
}

extension LeapModel: Fetchable {
}
