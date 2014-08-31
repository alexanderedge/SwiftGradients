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
        
        let newColours = NSMutableArray.array()
        for _ in 1...numberOfColours {
            newColours.addObject(UIColor.randomColour().CGColor)
        }

        if (animated) {
            let anim = CABasicAnimation(keyPath: "colors")
            anim.fromValue = self.colors
            anim.toValue = newColours
            anim.duration = animationDuration
            self.addAnimation(anim, forKey: "changeColours")
        }
        
        self.colors = newColours;
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
}

class GradientView : UIView {
    
    var rotation : CGFloat = 0.0 {
        willSet(newRotation) {
            let layer : GradientLayer = self.layer as GradientLayer
            layer.rotate(newRotation);
        }
    }
    
    func randomAngle() -> CGFloat {
        return CGFloat(arc4random_uniform(1000)) / 1000.0 * CGFloat(M_PI)
    }
    
    override func willMoveToSuperview(newSuperview: UIView?) {
        super.willMoveToSuperview(newSuperview);
        self.changeGradient(false);
    }
    
    func changeGradient(animated : Bool) {
        let layer : GradientLayer = self.layer as GradientLayer
        layer.changeGradient(animated)
        self.rotation = randomAngle()
    }
    
    override class func layerClass() -> AnyClass {
        return GradientLayer.self
    }
    
    override func canBecomeFirstResponder() -> Bool {
        return true
    }

}