//
//  TestUtil.swift
//  Leap
//
//  Created by Kiril Savino on 3/31/17.
//  Copyright © 2017 Single Leap, Inc. All rights reserved.
//

import Foundation
import RealmSwift
@testable import Leap

var __testModels: [String:TestModel] = [:]

class TestModel: LeapModel {
    dynamic var title: String = ""
    dynamic var count: Int = 0

    func register() {
        __testModels[self.id] = self
    }

    static func by(id: String) -> TestModel? {
        return __testModels[id]
    }
}

class TestSurface: Surface {
    override var type: String { return "test" }

    let title = SurfaceString()
    let count = SurfaceInt()
    let magic = ComputedSurfaceInt<TestSurface>(by: {surface in return 88})

    static func load(byId id: String) -> TestSurface? {
        let model = TestModel.by(id: id)!
        let surface = TestSurface(id: id)
        let bridge = SurfaceBridge(id: id)
        bridge.addReferenceDirectly(TestModelReference(to: model, as: "test"))
        bridge.bindAll(surface.title, surface.count)
        surface.store = bridge
        surface.populate()
        return surface
    }
}

class TestModelReference: ModelReference<TestModel> {
    var _model: TestModel
    override init(to model: TestModel, as name: String) {
        _model = model
        super.init(to: model, as: name)
    }

    override func model() -> TestModel {
        print("resolving via TestModelReference")
        return _model
    }
}
