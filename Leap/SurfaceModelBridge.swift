//
//  SurfaceModelBridge.swift
//  Leap
//
//  Created by Kiril Savino on 3/29/17.
//  Copyright © 2017 Single Leap, Inc. All rights reserved.
//

import Foundation
import RealmSwift


typealias ModelGetter = (LeapModel) -> Any?
typealias ModelSetter = (LeapModel, Any?) -> Void

let setNothing = { (model:LeapModel, value:Any?) in return }
let getNothing = { (model:LeapModel) in return nil as Any? }

class SurfaceModelBridge: BackingStore {

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

    func dereference(_ name: String, index: Int) -> LeapModel? {
        if let query = references[name] as? Results {
            return query[index] as? LeapModel
        }
        return nil
    }

    func reference<Model:LeapModel>(_ model: Model, as name: String) where Model:Fetchable {
        references[name] = refer(to: model, as: name)
    }

    func referenceArray<M:LeapModel,S:Surface>(_ query: Results<M>, using: S.Type, as name: String) where S:ModelLoadable {
        references[name] = QueryBridge<M,S>(query)
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
        bind(property, populateWith: get, on: model, persistWith: set)
    }

    func bind(_ property: Property, populateWith get: @escaping ModelGetter, on model: String, persistWith set: @escaping ModelSetter) {
        guard references[model] is Reference else {
            fatalError("Can't bind a Reference-type value to \(String(describing:references[model])) type '\(model)'")
        }
        bindings[property.key] = (model, get, set)
    }

    func bindAll(_ properties:Property...) {
        properties.forEach { property in bind(property) }
    }

    func readonlyBind(_ property: Property, populateWith get: @escaping ModelGetter, on model: String) {
        bind(property, populateWith: get, on: model, persistWith: setNothing)
    }

    // this is separate from above, as opposed to using an optional arg,
    // because then you can use the final closure syntax in this common case
    func readonlyBind(_ property: Property, populateWith get: @escaping ModelGetter) {
        guard references.count == 1 else {
            fatalError("Need to specify model to do lookup on when more than one model bound")
        }
        let model = references.keys.first!
        bind(property, populateWith: get, on: model, persistWith: setNothing)
    }

    func bindArray(_ property: Property, to name: String? = nil) {
        let key = name ?? property.key
        guard references[key] is ArrayMaterializable else {
            fatalError("Can't bind a Array-type value to \(String(describing:references[key])) type '\(key)'")
        }
        bind(property, populateWith: getNothing, on: key, persistWith: setNothing)
    }

    func populate(_ surface: Surface) {
        var data: ModelData = [:]
        for (key, (sourceName, getFromModel, _)) in bindings {
            let source = references[sourceName]
            switch source {
            case let reference as Reference:
                if let model = reference.resolve(),
                    let value = getFromModel(model) {
                    data[key] = value
                }
            case let query as ArrayMaterializable:
                data[key] = query.materialize()
            default:
                fatalError("It's not OK not to have a source referred to in a binding \(key)")
            }
        }
        try! surface.update(data: data, via: self)
    }

    @discardableResult
    func persist(_ surface: Surface) -> Bool {
        var mutated = false
        let realm = Realm.user()

        try! realm.write {
            for (key, (modelName, _, set)) in bindings {
                if let value = surface.getValue(for: key), let model = dereference(modelName) {
                    set(model, value)
                    mutated = true
                    realm.add(model, update: true)
                }
            }
        }
        return mutated
    }
}


protocol ModelLoadable {
    static func load(fromModel: LeapModel) -> Surface?
}

protocol ArrayMaterializable {
    func materialize() -> [Surface]
}

class QueryBridge<Model:LeapModel,SomeSurface:Surface> where SomeSurface:ModelLoadable  {
    let query: Results<Model>

    init(_ query: Results<Model>) {
        self.query = query
    }

    func materialize() -> [Surface] {
        var results: [Surface] = []
        for object:Model in query {
            if let s = SomeSurface.load(fromModel: object) {
                results.append(s)
            }
        }
        return results
    }
}
