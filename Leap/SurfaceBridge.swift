//
//  SurfaceBridge.swift
//  Leap
//
//  Created by Kiril Savino on 3/29/17.
//  Copyright © 2017 Single Leap, Inc. All rights reserved.
//

import Foundation

typealias ModelGetter = (LeapModel) -> Any?
typealias ModelSetter = (LeapModel, Any?) -> Void

let setNothing = { (model:LeapModel, value:Any?) in return }

class SurfaceBridge: BackingStore {

    let sourceId: String

    init(id: String) {
        sourceId = id
    }

    fileprivate var references: [String:Any] = [:]
    fileprivate var bindings: [String: (String,ModelGetter,ModelSetter)] = [:]

    func dereference(_ name: String) -> LeapModel? {
        if let reference = references[name] as? Reference,
            let model = reference.resolve() {
            return model
        }
        return nil
    }

    func reference<Model:LeapModel>(_ model: Model, as name: String) where Model:Fetchable {
        references[name] = refer(to: model, as: name)
    }

    func addReferenceDirectly(_ reference: Reference) {
        references[reference.name] = reference
    }

    func bind(_ property: Property, to modelKey: String? = nil, on modelName: String? = nil) {
        guard modelName != nil || references.count == 1 else {
            fatalError("Need to specify model to do lookup on when more than one model bound")
        }
        let model = modelName ?? references.keys.first!
        let finalModelKey = (modelKey ?? property.key)
        let keys = finalModelKey.components(separatedBy: ".")
        let get = { (model:LeapModel) in return model.getValue(forKeysRecursively: keys) }
        let set = { (model:LeapModel, value:Any?) in model.set(value: value, forKeyPath: finalModelKey); return }
        _bind(property, populateWith: get, on: model, persistWith: set)
    }

    func _bind(_ property: Property, populateWith get: @escaping ModelGetter, on model: String, persistWith set: @escaping ModelSetter) {
        bindings[property.key] = (model, get, set)
    }

    func readonlyBind(_ property: Property, to populate: @escaping ModelGetter, on model: String) {
        _bind(property, populateWith: populate, on: model, persistWith: setNothing)
    }

    func readonlyBind(_ property: Property, to populate: @escaping ModelGetter) {
        guard references.count == 1 else {
            fatalError("Need to specify model to do lookup on when more than one model bound")
        }
        let model = references.keys.first!
        _bind(property, populateWith: populate, on: model, persistWith: setNothing)
    }

    func bindAll(_ properties:Property...) {
        properties.forEach { property in bind(property) }
    }

    func populate(_ surface: Surface) {
        var data: ModelData = [:]
        for (key, (sourceName, getFromModel, _)) in bindings {
            if let model = dereference(sourceName),
                let value = getFromModel(model) {
                data[key] = value
            }
        }
        try! surface.update(data: data, via: self)
    }

    @discardableResult
    func persist(_ surface: Surface) throws -> Bool {
        var mutated = false
        for (key, (modelName, _, set)) in bindings {
            if let value = surface.getValue(for: key), let model = dereference(modelName) {
                set(model, value)
                mutated = true
            }
        }
        return mutated
    }
}
