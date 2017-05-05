//
//  RaggedEdgeView.swift
//  Leap
//
//  Created by Kiril Savino on 5/5/17.
//  Copyright © 2017 Single Leap, Inc. All rights reserved.
//

import UIKit

class RaggedEdgeView: UIView {
    override func draw(_ rect: CGRect) {
        // Drawing code
        /*
         let width = givenView.frame.size.width
         let height = givenView.frame.size.height

         let givenFrame = givenView.frame
         let zigZagWidth = CGFloat(7)
         let zigZagHeight = CGFloat(5)
         let yInitial = height-zigZagHeight

         var zigZagPath = UIBezierPath()
         zigZagPath.moveToPoint(CGPointMake(0, 0))
         zigZagPath.addLineToPoint(CGPointMake(0, yInitial))

         var slope = -1
         var x = CGFloat(0)
         var i = 0
         while x < width {
         x = zigZagWidth * CGFloat(i)
         let p = zigZagHeight * CGFloat(slope)
         let y = yInitial + p
         let point = CGPointMake(x, y)
         zigZagPath.addLineToPoint(point)
         slope = slope*(-1)
         i++
         }
         zigZagPath.addLineToPoint(CGPointMake(width, 0))

         var shapeLayer = CAShapeLayer()
         shapeLayer.path = zigZagPath.CGPath
         givenView.layer.mask = shapeLayer
 */
    }
}
