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
    static func by(id: String) -> LeapModel?
}


extension Fetchable where Self:LeapModel {
    static func by(id: String) -> Self? {
        return Realm.user().objects(Self.self).filter("id = %@", id).first
    }
}

extension LeapModel: Fetchable {
}


/*

extension LeapModel {
    static func by<Model:LeapModel>(id: String) -> Model? where Model:Fetchable {
        let realm = Realm.user()
        let query = realm.objects(Model.self)
        return query.filter("id = %@", id).first
    }
}

 */
