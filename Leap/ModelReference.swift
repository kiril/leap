//
//  ModelReference.swift
//  Leap
//
//  Created by Kiril Savino on 3/28/17.
//  Copyright © 2017 Single Leap, Inc. All rights reserved.
//

import Foundation


typealias ModelGetter = (String) -> LeapModel?

protocol Reference {
    var name: String { get }
    func resolve() -> LeapModel?
}

class ModelReference<Model:LeapModel>: Reference where Model:Fetchable {
    var getter: ModelGetter
    var id: String
    var name: String

    init(model: Model, name: String) {
        id = model.id
        getter = Model.by
        self.name = name
    }

    func resolve() -> LeapModel? {
        return getter(id)
    }
}
