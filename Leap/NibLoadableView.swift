//
//  NibLoadableView.swift
//  Leap
//
//  Created by Chris Ricca on 4/4/17.
//  Copyright © 2017 Single Leap, Inc. All rights reserved.
//

import UIKit

protocol NibLoadableView: class {
    static var nibName: String { get }
}

extension NibLoadableView where Self: UIView {
    static var nibName: String {
        return String(describing: self)
    }

    private func loadViewFromNib(nibName: String = Self.nibName) -> UIView {
        let bundle = Bundle(for: Self.self)
        let nib = UINib(nibName: nibName, bundle: bundle)
        let view = nib.instantiate(withOwner: self, options: nil).first as! UIView
        return view
    }

    func setupUsingNibContent(nibName: String = Self.nibName) {

        let view = loadViewFromNib(nibName: nibName)

        self.addSubview(view)
        view.leftAnchor.constraint(equalTo: self.leftAnchor).isActive = true
        view.topAnchor.constraint(equalTo: self.topAnchor).isActive = true
        view.rightAnchor.constraint(equalTo: self.rightAnchor).isActive = true
        view.bottomAnchor.constraint(equalTo: self.bottomAnchor).isActive = true

        view.translatesAutoresizingMaskIntoConstraints = false
        self.sendSubview(toBack: view)
    }
}
