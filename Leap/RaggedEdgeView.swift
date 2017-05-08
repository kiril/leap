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
    static let ZAG_HEIGHT: CGFloat = 8.0

    var edgeDisposition = EdgeDisposition.outie
    var lineColor = UIColor.projectLightGray
    var maskColor = UIColor.white
    var borderWidth: CGFloat = 2.0

    var zigWidth: CGFloat { return frame.size.width / CGFloat(RaggedEdgeView.ZIG_COUNT) }
    var zagHeight: CGFloat { return min(frame.size.height, RaggedEdgeView.ZAG_HEIGHT) }

    func drawEdge(in rect: CGRect) {
        let width = frame.size.width
        let height = frame.size.height

        let path = UIBezierPath()
        let bottom = zagHeight
        let top: CGFloat = 0.5
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

        let leftEdge: CGFloat = 1.0
        let rightEdge: CGFloat = width - 1.0

        var startPoint: CGPoint!
        var endPoint: CGPoint!
        var z = ZigZag.zig

        switch edgeDisposition {
        case .outie:
            startPoint = CGPoint(x: leftEdge, y: top)
            endPoint = CGPoint(x: rightEdge, y: top)
            z = .zig

        case .innie:
            startPoint = CGPoint(x: leftEdge, y: bottom)
            endPoint = CGPoint(x: rightEdge, y: bottom)
            z = .zag
        }


        path.move(to: CGPoint(x: leftEdge, y: height))
        path.addLine(to: startPoint)

        var x = zigWidth / 2.0
        var y = startPoint.y

        while abs(rightEdge-x) > 1.0 {
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
        path.addLine(to: CGPoint(x: rightEdge, y: height))
        
        lineColor.setStroke()
        path.lineWidth = borderWidth
        path.stroke()

        path.close()
        maskColor.setFill()
        path.fill()
    }

    override func draw(_ rect: CGRect) {
        drawEdge(in: rect)
    }
}
