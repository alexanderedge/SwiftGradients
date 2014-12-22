//
//  GradientView.swift
//  SwiftGradients
//
//  Created by Alexander G Edge on 31/08/2014.
//  Copyright (c) 2014 Alexander Edge Ltd. All rights reserved.
//

import Foundation
import UIKit
import QuartzCore

extension UIColor {
    class func randomComponent() -> CGFloat {
        return CGFloat(arc4random_uniform(255)) / 255.0
    }
    class func randomColour() -> UIColor {
        return UIColor(red: randomComponent(), green: randomComponent(), blue: randomComponent(), alpha: 1.0)
    }
}

class GradientView : UIView {

    var gradient : CGGradientRef?
    
    var rotation : CGFloat = 0.0 {
        didSet(newRotation) {
            self.setNeedsDisplay()
        }
    }
    
    override func willMoveToSuperview(newSuperview: UIView?) {
        super.willMoveToSuperview(newSuperview);
        self.changeGradient(false);
    }
    
    func changeGradient(animated : Bool) {
    
        var colors = NSMutableArray()
        for _ in 1...2 {
            colors.addObject(UIColor.randomColour().CGColor)
        }
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        self.gradient = CGGradientCreateWithColors(colorSpace, colors, [0.0,1.0])

        self.rotation = randomAngle()
        self.setNeedsDisplay()
    
    }
    
    override func canBecomeFirstResponder() -> Bool {
        return true
    }

    override func drawRect(rect: CGRect) {
        
        let ctx = UIGraphicsGetCurrentContext()

        var startPoint = startPointForAngle(self.rotation)
        startPoint.x *= CGRectGetWidth(rect);
        startPoint.y *= CGRectGetHeight(rect);
        
        var endPoint = endPointForAngle(self.rotation)
        endPoint.x *= CGRectGetWidth(rect);
        endPoint.y *= CGRectGetHeight(rect);
        
        let options : CGGradientDrawingOptions = UInt32(kCGGradientDrawsBeforeStartLocation | kCGGradientDrawsAfterEndLocation)
        CGContextDrawLinearGradient(ctx, self.gradient, startPoint, endPoint, options)
    }
    
    private func startPointForAngle(angle : CGFloat) -> CGPoint {
        return CGPointMake(0.5 + (sin(angle) / 2.0), 0.5 - cos(angle) / 2.0)
    }
    
    private func endPointForAngle(angle : CGFloat) -> CGPoint {
        return CGPointMake(0.5 - (sin(angle) / 2.0), 0.5 + cos(angle) / 2.0)
    }
    
    private func randomAngle() -> CGFloat {
        return CGFloat(arc4random_uniform(1000)) / 1000.0 * CGFloat(M_PI)
    }
    
}