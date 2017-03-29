//
//  SurfaceBridge.swift
//  Leap
//
//  Created by Kiril Savino on 3/29/17.
//  Copyright © 2017 Single Leap, Inc. All rights reserved.
//

import Foundation

class SurfaceBridge: BackingStore {

    let sourceId: String

    init(id: String) {
        sourceId = id
    }

    fileprivate var references: [String:Any] = [:]
    fileprivate var bindings: [String:(String,[String])] = [:]

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

    func bind(_ property: Property, to name: String? = nil, on model: String? = nil) {
        guard model != nil || references.count == 1 else {
            fatalError("")
        }
        bindings[property.key] = (model ?? references.keys.first!, name?.components(separatedBy: ".") ?? [property.key])
    }

    func bindAll(_ properties:Property...) {
        properties.forEach { property in bind(property) }
    }

    func populate(_ surface: Surface) {
        var data: ModelData = [:]
        for (key, (sourceName, sourceKeyPath)) in bindings {
            if let model = dereference(sourceName),
                let value = model.getValue(forKeysRecursively: sourceKeyPath) {
                data[key] = value
            }
        }
        try! surface.update(data: data, via: self)
    }

    func persist(_ surface: Surface) throws -> Bool {
        return false
    }
}
