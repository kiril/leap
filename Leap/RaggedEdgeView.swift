//
//  RaggedEdgeView.swift
//  Leap
//
//  Created by Kiril Savino on 5/5/17.
//  Copyright © 2017 Single Leap, Inc. All rights reserved.
//

import UIKit

enum EdgeDisposition {
    case outie
    case innie
}

enum ZigZag {
    case zig
    case zag
}

class RaggedEdgeView: UIView {
    static let ZIG_COUNT = 10
    static let ZAG_HEIGHT: CGFloat = 10.0

    var edgeDisposition = EdgeDisposition.outie
    var lineColor = UIColor.projectLightGray

    override func draw(_ rect: CGRect) {
        let width = frame.size.width
        let height = frame.size.height

        let zigWidth: CGFloat = width / CGFloat(RaggedEdgeView.ZIG_COUNT)
        let zagHeight: CGFloat = RaggedEdgeView.ZAG_HEIGHT

        let path = UIBezierPath()
        let bottom = zagHeight
        let top: CGFloat = 0.0
        /*
         Outie:

         |\/\/\/\/\/\|
         |           |
         
         Innie:
         
         /\/\/\/\/\/\
         |          |
         
         Zig:
         \
         
         Zag:
         /
         */

        var startPoint: CGPoint!
        var endPoint: CGPoint!
        var z = ZigZag.zig

        switch edgeDisposition {
        case .outie:
            startPoint = CGPoint(x: 0.0, y: top)
            endPoint = CGPoint(x: width, y: top)
            z = .zig

        case .innie:
            startPoint = CGPoint(x: 0.0, y: bottom)
            endPoint = CGPoint(x: width, y: bottom)
            z = .zag
        }


        path.move(to: CGPoint(x: 0.0, y: height))
        path.addLine(to: startPoint)

        var x = zigWidth / 2.0
        var y = startPoint.y

        while abs(width-x) > 0.5 {
            switch z {
            case .zig: // down
                y += zagHeight
                z = .zag

            case .zag:
                y -= zagHeight
                z = .zig
            }

            path.addLine(to: CGPoint(x: x, y: y))

            x += zigWidth / 2.0
        }

        path.addLine(to: endPoint)
        path.addLine(to: CGPoint(x: width, y: height))

        //guard let context: CGContext? = UIGraphicsGetCurrentContext() else { fatalError() }

        path.stroke()
    }
}
