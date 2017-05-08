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

enum RaggedOrientation {
    case top
    case bottom
}

class RaggedEdgeView: UIView {
    static let ZIG_COUNT = 12
    static let ZAG_HEIGHT: CGFloat = 8.0

    var edgeDisposition = EdgeDisposition.outie
    var lineColor = UIColor.projectLightGray
    var maskColor = UIColor.white
    var borderWidth: CGFloat = 1.0
    var orientation = RaggedOrientation.top

    var zigWidth: CGFloat { return frame.size.width / CGFloat(RaggedEdgeView.ZIG_COUNT) }
    var zagHeight: CGFloat { return min(frame.size.height, RaggedEdgeView.ZAG_HEIGHT) }

    func zigZagPath(in rect: CGRect) -> UIBezierPath {
        let width = frame.size.width
        let height = frame.size.height

        let path = UIBezierPath()
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

        let leftEdge: CGFloat = 0.5
        let rightEdge: CGFloat = width - 0.5
        let topEdge: CGFloat = 0.5
        let bottomEdge: CGFloat = height - 0.5

        var verticalMovement = zagHeight
        var startPoint: CGPoint!
        var zigZagStartPoint: CGPoint!
        var endPoint: CGPoint!
        var zigZagEndPoint: CGPoint!
        var z = ZigZag.zig

        switch orientation {
        case .top:
            startPoint = CGPoint(x: leftEdge, y: height)
            endPoint = CGPoint(x: rightEdge, y: height)

            switch edgeDisposition {
            case .outie:
                zigZagStartPoint = CGPoint(x: leftEdge, y: topEdge)
                zigZagEndPoint = CGPoint(x: rightEdge, y: topEdge)
                z = .zig

            case .innie:
                zigZagStartPoint = CGPoint(x: leftEdge, y: zagHeight)
                zigZagEndPoint = CGPoint(x: rightEdge, y: zagHeight)
                z = .zag
            }

        case .bottom:
            startPoint = CGPoint(x: leftEdge, y: 0.0)
            endPoint = CGPoint(x: rightEdge, y: 0.0)
            verticalMovement *= -1

            switch edgeDisposition {
            case .outie:
                zigZagStartPoint = CGPoint(x: leftEdge, y: bottomEdge)
                zigZagEndPoint = CGPoint(x: rightEdge, y: bottomEdge)
                z = .zig

            case .innie:
                zigZagStartPoint = CGPoint(x: leftEdge, y: bottomEdge-zagHeight)
                zigZagEndPoint = CGPoint(x: rightEdge, y: bottomEdge-zagHeight)
                z = .zag
            }
        }


        path.move(to: startPoint)
        path.addLine(to: zigZagStartPoint)

        var x = zigWidth / 2.0
        var y = zigZagStartPoint.y

        while abs(rightEdge-x) > 1.0 {
            switch z {
            case .zig: // down
                y += verticalMovement
                z = .zag

            case .zag:
                y -= verticalMovement
                z = .zig
            }
            
            path.addLine(to: CGPoint(x: x, y: y))
            
            x += zigWidth / 2.0
        }
        
        path.addLine(to: zigZagEndPoint)
        path.addLine(to: endPoint)

        return path
    }

    override func draw(_ rect: CGRect) {
        guard frame.size.height > 1 else { return }

        let fillPath = zigZagPath(in: rect)
        fillPath.close()
        maskColor.setFill()
        fillPath.fill()

        let borderPath = zigZagPath(in: rect)
        lineColor.setStroke()
        borderPath.lineWidth = borderWidth
        borderPath.stroke()
    }
}
