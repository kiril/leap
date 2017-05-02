//
//  ModelReference.swift
//  Leap
//
//  Created by Kiril Savino on 3/28/17.
//  Copyright © 2017 Single Leap, Inc. All rights reserved.
//

import Foundation


protocol Reference {
    var name: String { get }
    var id: String { get }
    func resolve() -> LeapModel?
}

func refer<Model:LeapModel>(to model: Model, as name: String) -> ModelReference<Model> where Model:Fetchable {
    return ModelReference<Model>(to: model, as: name)
}

class ModelReference<Model:LeapModel>: Reference where Model:Fetchable {
    var id: String
    var name: String

    init(to model: Model, as name: String) {
        id = model.id
        self.name = name
    }

    final func resolve() -> LeapModel? {
        return model()
    }

    final func model() -> Model? {
        return Model.by(id: id)
    }
}
