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
}

extension LeapModel {
    static func by<Model:LeapModel>(id: String) -> Model? where Model:Fetchable {
        let realm = Realm.user()
        let query = realm.objects(Model.self)
        return query.filter("id = %@", id).first
    }
}
