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


private enum Binding {
    case array(name: String)
    case read(name: String, getter: ModelGetter)
    case readwrite(name: String, getter: ModelGetter, setter: ModelSetter)
}

let setNothing = { (model:LeapModel, value:Any?) in return }
let getNothing = { (model:LeapModel) in return nil as Any? }

class SurfaceModelBridge<SomeSurface:Surface>: BackingStore {

    let sourceId: String
    weak var surface: SomeSurface?
    private var notificationTokens: [NotificationToken] = []

    required init(id: String, surface: SomeSurface) {
        sourceId = id
        self.surface = surface
    }

    deinit {
        notificationTokens.forEach { token in token.stop() }
    }

    fileprivate var references: [String: Any] = [:]
    fileprivate var bindings: [String: Binding] = [:]

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

    func referenceArray<M:LeapModel,S:Surface>(
                        _ query: Results<M>,
                        using: S.Type,
                        as name: String,
                        withNotifications: Bool = true) where S:ModelLoadable {
        
        references[name] = QueryBridge<M,S>(query)

        if withNotifications {
            let token = query.addNotificationBlock { [weak self] (_: RealmCollectionChange<Results<M>>) in
                if let bridge = self {
                    bridge.updateReceived(forSource: name)
                }
            }
            notificationTokens.append(token)
        }
    }

    func addReferenceDirectly(_ reference: Reference) {
        references[reference.name] = reference
    }

    private func updateReceived(forSource name: String) {
        guard let surface = self.surface else {
            print("No surface, discarding source update")
            return
        }
        self.populateOnly(surface, restrictTo: name)
    }

    func bind(_ property: Property, to modelKey: String? = nil, on modelName: String? = nil) {
        guard modelName != nil || references.count == 1 else {
            fatalError("Need to specify model to do lookup on when more than one model bound")
        }
        let model = modelName ?? references.keys.first!
        guard references[model] is Reference else {
            fatalError("Can't bind a Reference-type value to \(String(describing:references[model])) type '\(model)'")
        }
        let finalModelKey = (modelKey ?? property.key)
        let keys = finalModelKey.components(separatedBy: ".")
        let get = { (model:LeapModel) in return model.getValue(forKeysRecursively: keys) }
        let set = { (model:LeapModel, value:Any?) in model.set(value: value, forKeyPath: finalModelKey); return }
        bindings[property.key] = .readwrite(name: model, getter: get, setter: set)
    }

    func bind(_ property: Property, populateWith get: @escaping ModelGetter, on model: String, persistWith set: @escaping ModelSetter) {
        bindings[property.key] = .readwrite(name: model, getter: get, setter: set)
    }

    func bindAll(_ properties:Property...) {
        properties.forEach { property in bind(property) }
    }

    func readonlyBind(_ property: Property, populateWith get: @escaping ModelGetter, on model: String) {
        guard references[model] is Reference else {
            fatalError("Can't bind a Reference-type value to \(String(describing:references[model])) type '\(model)'")
        }
        bindings[property.key] = .read(name: model, getter: get)
    }

    func readonlyBind(_ property: Property) {
        bindings[property.key] = .read(name: references.keys.first!,
                                       getter: { $0.getValue(forKeysRecursively: property.key.components(separatedBy: ".")) })
    }

    // this is separate from above, as opposed to using an optional arg,
    // because then you can use the final closure syntax in this common case
    func readonlyBind(_ property: Property, populateWith get: @escaping ModelGetter) {
        guard references.count == 1 else {
            fatalError("Need to specify model to do lookup on when more than one model bound")
        }
        let model = references.keys.first!
        readonlyBind(property, populateWith: get, on: model)
    }

    func bindArray(_ property: Property, to name: String? = nil) {
        let key = name ?? property.key
        guard references[key] is ArrayMaterializable else {
            fatalError("Can't bind a Array-type value to \(String(describing:references[key])) type '\(key)'")
        }
        bindings[property.key] = .array(name: key)
    }

    func populate(_ surface: Surface) {
        populate(surface, with: nil, as: nil)
    }

    func populate(_ surface: Surface, with model: LeapModel?, as key: String?) {
        _populate(surface as! SomeSurface, with: model, as: key)
    }

    private func populateOnly(_ surface: SomeSurface, restrictTo onlyName: String) {
        _populate(surface, restrictTo: onlyName)
    }

    func _populate(_ surface: SomeSurface, restrictTo onlyName: String? = nil, with model: LeapModel? = nil, as key: String? = nil) {
        var modelCache: [String:LeapModel] = [:]
        if let m = model, let k = key {
            modelCache[k] = m
        }
        var arrayCache: [String:[Surface]] = [:]
        func getModel(_ name: String) -> LeapModel? {
            var ret = modelCache[name]
            if ret == nil {
                if let ref = references[name] as? Reference {
                    ret = ref.resolve()
                }
                if let ret = ret {
                    modelCache[name] = ret
                }
            }
            return ret
        }

        func getArray(_ name: String) -> [Surface]? {
            var ret = arrayCache[name]
            if ret == nil {
                if let ref = references[name] as? ArrayMaterializable {
                    ret = ref.materialize()
                }
                if let ret = ret {
                    arrayCache[name] = ret
                }
            }
            return ret
        }

        var madeChanges = false

        var data: ModelData = [:]
        for (key, binding) in bindings {

            switch binding {
            case let .readwrite(name, get, _):
                if let onlyName = onlyName, onlyName != name {
                    break
                }
                if let model = getModel(name),
                    let value = get(model),
                    value !~=? data[key] {
                    madeChanges = true
                    data[key] = value
                }

            case let .read(name, get):
                if let onlyName = onlyName, onlyName != name {
                    break
                }
                if let model = getModel(name),
                    let value = get(model),
                    value !~=? data[key] {
                    madeChanges = true
                    data[key] = value
                }

            case let .array(name):
                if let onlyName = onlyName, onlyName != name {
                    break
                }
                if let array = getArray(name),
                    array !~=? data[key] {
                    madeChanges = true
                    data[key] = array
                }
                break
            }
        }

        guard madeChanges else {
            return
        }

        if let key = onlyName {
            try! surface.update(key: key, toValue: data[key]!, via: self, silently: false)
        } else {
            try! surface.update(data: data, via: self)
        }

        surface.lastPersisted = Date.timeIntervalSinceReferenceDate
    }

    @discardableResult
    func persist(_ surface: Surface) -> Bool {
        var mutated = false
        let realm = Realm.user()

        try! realm.write {
            for (key, binding) in bindings {
                switch binding {
                case let .readwrite(name, _, set):
                    if let value = surface.getValue(for: key),
                        let model = dereference(name) {
                        set(model, value)
                        realm.add(model, update: true)
                        mutated = true
                    }
                    break

                default:
                    break
                }
            }
        }
        surface.lastPersisted = Date.timeIntervalSinceReferenceDate
        return mutated
    }
}


protocol ModelLoadable {
    static func load(with model: LeapModel) -> Surface?
}

protocol ArrayMaterializable {
    func materialize() -> [Surface]
}

class QueryBridge<Model:LeapModel,SomeSurface:Surface>: ArrayMaterializable where SomeSurface:ModelLoadable  {
    let query: Results<Model>

    init(_ query: Results<Model>) {
        self.query = query
    }

    func materialize() -> [Surface] {
        var results: [Surface] = []
        for object:Model in query {
            if let s = SomeSurface.load(with: object) {
                results.append(s)
            }
        }
        return results
    }
}
