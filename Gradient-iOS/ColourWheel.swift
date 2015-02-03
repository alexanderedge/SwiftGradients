//  ColourWheel.swift
//
//  Copyright (c) 2015 Alexander Edge
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//  THE SOFTWARE.

import UIKit

class ColourWheel : UIView {
    
    var saturation : CGFloat = 1
    var brightness : CGFloat = 1
    var focalHue : CGFloat = 0
    var focalAngle : CGFloat = 0
    
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.opaque = false
    }

    required init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    
    
    // get it to repeat the cycle every quadrant
    
    override func drawRect(frame: CGRect) {
        
        let lineWidth : CGFloat = 1
        
        let rad : CGFloat = CGRectGetWidth(frame) / 2 - lineWidth
        let center = CGPointMake(CGRectGetWidth(frame) / 2, CGRectGetHeight(frame) / 2)
        
        // go around the circle drawing an arc of colour
                
        let ctx = UIGraphicsGetCurrentContext()
        
        CGContextSetLineWidth(ctx, lineWidth)
        CGContextSetMiterLimit(ctx, 0)
        CGContextSetAllowsAntialiasing(ctx, true)
        CGContextSetShouldAntialias(ctx, true)
        
        let offset = focalAngle / CGFloat(2 * M_PI)
        
        let startHue = moduloHue(focalHue - offset)
        
        let segments = 360
        let arcAngle = CGFloat(2 * M_PI) / CGFloat(segments)
        
        var start : CGFloat = 0
        var end : CGFloat = 0
        
        for segment in 0..<segments {
            
            CGContextSaveGState(ctx)
            
            let hue = moduloHue(startHue + 1 / CGFloat(segments) * CGFloat(segment))
            
            let colour = UIColor(hue: CGFloat(hue), saturation: saturation, brightness: brightness, alpha: 1)
            colour.setFill()
            colour.setStroke()
            end = start + arcAngle
            
            let arcStartX = center.x + rad * cos(start)
            let arcStartY = center.y + rad * sin(start)
            
            CGContextMoveToPoint(ctx, center.x, center.y)
            CGContextAddArc(ctx, center.x, center.y, rad, start, end, 0)
            CGContextDrawPath(ctx, kCGPathFillStroke)
            
            CGContextRestoreGState(ctx)
            
            start = end
        }
        
        
    }
    
    private func moduloHue(hue : CGFloat) -> CGFloat {
        if hue < 1 {
            return hue
        } else if hue < 1 {
            return hue + 1
        } else {
            return hue - 1
        }
    }
    
}