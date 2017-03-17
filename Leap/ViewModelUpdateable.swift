//
//  ViewModelUpdateable.swift
//  Leap
//
//  Created by Chris Ricca on 3/16/17.
//  Copyright © 2017 Kiril Savino. All rights reserved.
//

import Foundation

protocol ViewModelUpdateable {
    weak var delegate: ViewModelDelegate? { get set }
}

protocol ViewModelDelegate: class {
    func didUpdate(_ viewModel: ViewModelUpdateable)
}
