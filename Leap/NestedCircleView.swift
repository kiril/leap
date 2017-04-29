//
//  CircleView.swift
//  Leap
//
//  Created by Chris Ricca on 4/28/17.
//  Copyright © 2017 Single Leap, Inc. All rights reserved.
//

// bunch of inspiration / code from: http://stackoverflow.com/questions/26578023/animate-drawing-of-a-circle

import UIKit

class NestedCircleView: UIView {

    var topCircleColor = UIColor.projectBlue { didSet { updateCircleViews() } }
    var bottomCircleColor = UIColor.projectDarkGray { didSet { updateCircleViews() } }
    var backgroundCircleColor = UIColor.projectLighterGray { didSet { updateCircleViews() } }

    var topCircleComplete: CGFloat = 0.0 { didSet { updateCircleCompleteness() } }
    var bottomCircleComplete: CGFloat = 0.0 { didSet { updateCircleCompleteness() } }

    var circleWidth: CGFloat = 5.0

    private let topCircleLayer = CAShapeLayer()
    private let bottomCircleLayer = CAShapeLayer()
    private let backgroundCircleLayer = CAShapeLayer()


    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setup()
    }

    private func setup() {
        self.backgroundColor = UIColor.clear

        // Add the circleLayers to the view's layer's sublayers
        layer.addSublayer(backgroundCircleLayer)
        layer.addSublayer(bottomCircleLayer)
        layer.addSublayer(topCircleLayer)

        updateCircleViews()
        updateCircleCompleteness()
    }

    private func updateCircleViews() {
        setupCircleShapeLayer(topCircleLayer, withColor: topCircleColor.cgColor)
        setupCircleShapeLayer(bottomCircleLayer, withColor: bottomCircleColor.cgColor)
        setupCircleShapeLayer(backgroundCircleLayer, withColor: backgroundCircleColor.cgColor)
    }

    private func updateCircleCompleteness() {
        topCircleLayer.strokeEnd = max(0.0, min(1.0, topCircleComplete))
        bottomCircleLayer.strokeEnd = max(0.0, min(1.0, bottomCircleComplete))
    }

    private func setupCircleShapeLayer(_ shape: CAShapeLayer,
                                       withColor color: CGColor) {
        // Use UIBezierPath as an easy way to create the CGPath for the layer.
        // The path should be the entire circle.
        let circlePath = UIBezierPath(arcCenter: CGPoint(x: frame.size.width / 2.0,
                                                         y: frame.size.height / 2.0),
                                      radius: (frame.size.width - 10)/2,
                                      startAngle: CGFloat(.pi * -0.5),
                                      endAngle: CGFloat(.pi * 1.5),
                                      clockwise: true)

        // Setup the CAShapeLayer with the path, colors, and line width
        shape.path = circlePath.cgPath
        shape.fillColor = UIColor.clear.cgColor
        shape.strokeColor = color
        shape.lineWidth = circleWidth;
    }

}
