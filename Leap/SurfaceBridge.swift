//
//  SurfaceBridge.swift
//  Leap
//
//  Created by Kiril Savino on 3/29/17.
//  Copyright © 2017 Single Leap, Inc. All rights reserved.
//

import Foundation

typealias ModelLookup = (LeapModel) -> Any?
typealias SurfaceLookup = (Surface) -> Any?

class SurfaceBridge: BackingStore {

    let sourceId: String

    init(id: String) {
        sourceId = id
    }

    fileprivate var references: [String:Any] = [:]
    fileprivate var bindings: [String: (String,ModelLookup,SurfaceLookup?)] = [:]

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

    func bind(_ property: Property, to populationKey: String? = nil, on modelName: String? = nil) {
        guard modelName != nil || references.count == 1 else {
            fatalError("Need to specify model to do lookup on when more than one model bound")
        }
        let model = modelName ?? references.keys.first!
        let keys = (populationKey ?? property.key).components(separatedBy: ".")
        let fromModel = { (model:LeapModel) in
            return model.getValue(forKeysRecursively: keys)
        }
        let fromSurface = { (surface:Surface) in
            return surface.getValue(for: property.key)
        }
        _bind(property, populateWith: fromModel, on: model, returnWith: fromSurface)
    }

    func _bind(_ property: Property, populateWith getFromModel: @escaping ModelLookup, on model: String, returnWith getFromSurface: SurfaceLookup? = nil) {
        bindings[property.key] = (model, getFromModel, getFromSurface)
    }

    func readonlyBind(_ property: Property, to populate: @escaping ModelLookup, on model: String) {
        _bind(property, populateWith: populate, on: model)
    }

    func readonlyBind(_ property: Property, to populate: @escaping ModelLookup) {
        guard references.count == 1 else {
            fatalError("Need to specify model to do lookup on when more than one model bound")
        }
        let model = references.keys.first!
        _bind(property, populateWith: populate, on: model)
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

    func persist(_ surface: Surface) throws -> Bool {
        return false
    }
}
