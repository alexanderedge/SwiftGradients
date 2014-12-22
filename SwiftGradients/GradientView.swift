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

class GradientLayer : CAGradientLayer {
    
    let numberOfColours : UInt = 4
    let animationDuration : NSTimeInterval = 0.3
    
    func changeGradient(animated : Bool) {
        
        var newColours = NSMutableArray()
        for _ in 1...numberOfColours {
            newColours.addObject(UIColor.randomColour().CGColor)
        }

        let angle = randomAngle()
        let startPoint = startPointForAngle(angle)
        let endPoint = endPointForAngle(angle)
        
        if (animated) {
            let anim = CABasicAnimation(keyPath: "colors")
            anim.fromValue = self.colors
            anim.toValue = newColours
            anim.duration = animationDuration
            self.addAnimation(anim, forKey: "changeColours")

            let startPointAnim = CABasicAnimation(keyPath: "startPoint")
            startPointAnim.fromValue = NSValue(CGPoint:self.startPoint)
            startPointAnim.toValue = NSValue(CGPoint:startPoint)
            startPointAnim.duration = animationDuration
            self.addAnimation(startPointAnim, forKey: "changeStartPoint")
            
            let endPointAnim = CABasicAnimation(keyPath: "colors")
            endPointAnim.fromValue = NSValue(CGPoint:self.endPoint)
            endPointAnim.toValue = NSValue(CGPoint:endPoint)
            endPointAnim.duration = animationDuration
            self.addAnimation(endPointAnim, forKey: "changeEndPoint")
        }

        self.colors = newColours
        self.startPoint = startPoint
        self.endPoint = endPoint
    }
    
    func rotate(angle : CGFloat) {
        self.startPoint = startPointForAngle(angle)
        self.endPoint = endPointForAngle(angle)
    }
    
    func startPointForAngle(angle : CGFloat) -> CGPoint {
        return CGPointMake(0.5 + (sin(angle) / 2.0), 0.5 - cos(angle) / 2.0)
    }
    
    func endPointForAngle(angle : CGFloat) -> CGPoint {
        return CGPointMake(0.5 - (sin(angle) / 2.0), 0.5 + cos(angle) / 2.0)
    }
    
    func randomAngle() -> CGFloat {
        return CGFloat(arc4random_uniform(1000)) / 1000.0 * CGFloat(M_PI)
    }
}

class GradientView : UIView {

    var gradient : CGGradientRef?
    
    var rotation : CGFloat = 0.0 {
        willSet(newRotation) {
            let layer : GradientLayer = self.layer as GradientLayer
            layer.rotate(newRotation);
        }
        didSet(newRotation) {
            self.setNeedsDisplay()
        }
    }
    
    override func willMoveToSuperview(newSuperview: UIView?) {
        super.willMoveToSuperview(newSuperview);
        self.changeGradient(false);
    }
    
    func changeGradient(animated : Bool) {
        
        let layer : GradientLayer = self.layer as GradientLayer
        layer.changeGradient(animated)

    }
    
    override class func layerClass() -> AnyClass {
        return GradientLayer.self
    }
    
    override func canBecomeFirstResponder() -> Bool {
        return true
    }

}