//
//  ElapsedTimeProgressView.swift
//  Leap
//
//  Created by Chris Ricca on 5/16/17.
//  Copyright © 2017 Single Leap, Inc. All rights reserved.
//

import UIKit

@IBDesignable class TimeProgressView: UIView {

    enum ProgressViewEndCapType {
        case flat, rounded
    }

    @IBInspectable var progress: CGFloat = 0.0 {
        didSet { updateInnerProgressView() }
    }
    var progressColor = UIColor.black {
        didSet { updateInnerProgressView() }
    }
    var borderColor = UIColor.clear {
        didSet { updateBorder() }
    }
    var endCapType = ProgressViewEndCapType.flat {
        didSet { updateBorder() }
    }

    func setProgress(progress: CGFloat, withEdgeBuffer edgeBuffer: CGFloat) {
        self.progress = max(0.0 + edgeBuffer, min(1.0 - edgeBuffer, progress))
    }

    private lazy var innerProgressView = UIView()
    private var innerProgressViewWidthConstraint: NSLayoutConstraint?

    private func updateInnerProgressView() {
        innerProgressViewWidthConstraint?.isActive = false

        let progressPercent = max(0.0 , min(1.0, progress))
        innerProgressViewWidthConstraint = innerProgressView.widthAnchor.constraint(equalTo: widthAnchor,
                                                                                    multiplier: progressPercent,
                                                                                    constant: 0)
        innerProgressViewWidthConstraint?.isActive = true
        innerProgressView.backgroundColor = progressColor
    }

    override init(frame: CGRect) {
        super.init(frame: frame)

        setup()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)

        setup()
    }

    private func setup() {
        setupInnerProgressView()
        updateBorder()

        translatesAutoresizingMaskIntoConstraints = false
        innerProgressView.translatesAutoresizingMaskIntoConstraints = false
    }

    private func setupInnerProgressView() {
        addSubview(innerProgressView)

        innerProgressView.leftAnchor.constraint(equalTo: leftAnchor).isActive = true
        innerProgressView.topAnchor.constraint(equalTo: topAnchor).isActive = true
        innerProgressView.bottomAnchor.constraint(equalTo: bottomAnchor).isActive = true

        updateInnerProgressView()
    }

    private func updateBorder() {
        layer.masksToBounds = true
        layer.borderColor = borderColor.cgColor
        layer.borderWidth = 1.0

        switch endCapType {
        case .flat:
            layer.cornerRadius = 0
        case .rounded:
            layer.cornerRadius = bounds.height / 2.0
        }
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        updateBorder()
    }
}
