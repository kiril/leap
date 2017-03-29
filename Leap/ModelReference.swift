//
//  ModelReference.swift
//  Leap
//
//  Created by Kiril Savino on 3/28/17.
//  Copyright © 2017 Single Leap, Inc. All rights reserved.
//

import Foundation

typealias ModelGetter<Model:LeapModel> = (String) -> Model? where Model:Fetchable

protocol Reference {
    associatedtype Model
    var name: String { get }
    func resolve() -> Model?
}

func refer<Model:LeapModel>(to model: Model, as name: String) -> ModelReference<Model> where Model:Fetchable {
    return ModelReference<Model>(model: model, name: name)
}

class ModelReference<Model:LeapModel>: Reference where Model:Fetchable {
    var id: String
    var name: String

    init(model: Model, name: String) {
        id = model.id
        self.name = name
    }

    func resolve() -> Model? {
        return Model.by(id: id)
    }
}
