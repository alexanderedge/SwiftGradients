//  GradientView.swift
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

import Foundation
import QuartzCore

#if os(OSX)
    import AppKit
    typealias Color = NSColor
    typealias Image = NSImage
    typealias View = NSView
#else
    import UIKit
    typealias Color = UIColor
    typealias Image = UIImage
    typealias View = UIView
#endif

extension Color {
    class func randomComponent() -> CGFloat {
        return CGFloat(arc4random_uniform(255)) / 255.0
    }
    class func randomColour() -> Color {
        return Color(red: randomComponent(), green: randomComponent(), blue: randomComponent(), alpha: 1.0)
    }
    func colorByShiftingHue(shift : CGFloat) -> Color {
        assert(shift < 1.0)
        var hue : CGFloat = 0
        var saturation : CGFloat = 0
        var brightness : CGFloat = 0
        var alpha : CGFloat = 0
        self.getHue(&hue, saturation: &saturation, brightness: &brightness, alpha: &alpha)
        hue += shift
        if hue > 1 {
            hue -= 1
        }
        return Color(hue:hue, saturation: saturation, brightness: brightness, alpha: alpha);
    }
}

class GradientView : View {
    
    var colors : Array<CGColor> = [Color.randomColour().CGColor,Color.randomColour().CGColor]
    
    private func refreshDisplay() {
        #if os(OSX)
            self.needsDisplay = true
        #else
            self.setNeedsDisplay()
        #endif
    }
    
    private func currentContext() -> CGContextRef {
        #if os(OSX)
            return NSGraphicsContext.currentContext()!.CGContext
        #else
            return UIGraphicsGetCurrentContext()
        #endif
    }
    
    var rotation : CGFloat = 0.0 {
        didSet(newRotation) {
            refreshDisplay()
        }
    }
    
    #if os(iOS)
    
    override func willMoveToSuperview(newSuperview: View?) {
        super.willMoveToSuperview(newSuperview);
        self.changeGradient(false);
    }
    
    override func canBecomeFirstResponder() -> Bool {
        return true
    }

    #endif
    
    func changeGradient(animated : Bool) {
    
        var colors = Array<CGColor>()
        for _ in 1...2 {
            colors.append(Color.randomColour().CGColor)
        }
        self.colors = colors
        
        self.rotation = GradientView.randomAngle()
        
        refreshDisplay()
        
    }
    
    func colorAtPosition(position : Int) -> Color {
        return Color(CGColor: self.colors[position])!
    }
    
    func setColor(colour:Color, atPosition position: Int) {
        self.colors[position] = colour.CGColor
        refreshDisplay()
    }
    
    override func drawRect(rect: CGRect) {
        
        let ctx = currentContext()

        var startPoint = GradientView.startPointForAngle(self.rotation)
        startPoint.x *= CGRectGetWidth(rect);
        startPoint.y *= CGRectGetHeight(rect);
        
        var endPoint = GradientView.endPointForAngle(self.rotation)
        endPoint.x *= CGRectGetWidth(rect);
        endPoint.y *= CGRectGetHeight(rect);
        
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        let gradient = CGGradientCreateWithColors(colorSpace, self.colors, [0.0,1.0])

        let options : CGGradientDrawingOptions = UInt32(kCGGradientDrawsBeforeStartLocation | kCGGradientDrawsAfterEndLocation)
        CGContextDrawLinearGradient(ctx, gradient, startPoint, endPoint, options)
    }
    
    func colourAtPoint(point: CGPoint) -> Color {
        
        #if os(iOS)
        let bitmapInfo = CGBitmapInfo(CGImageAlphaInfo.PremultipliedLast.rawValue)
        let pixelData = UnsafeMutablePointer<UInt8>.alloc(1)
        let ctx = CGBitmapContextCreate(pixelData, 1, 1, 8, 4, CGColorSpaceCreateDeviceRGB(), bitmapInfo)
        
        CGContextTranslateCTM(ctx, -point.x, -point.y)
        
        self.layer.renderInContext(ctx)
        
        
        let red = CGFloat(pixelData[0])
        let green = CGFloat(pixelData[1])
        let blue = CGFloat(pixelData[2])
        let alpha = CGFloat(pixelData[3])
        
        let color = UIColor(red:CGFloat(red / CGFloat(255)),green:CGFloat(green / CGFloat(255)),blue:CGFloat(blue / CGFloat(255)),alpha:1)
        
        return color
        #else
            
        return Color.whiteColor()
        #endif
    }
    
    class func startPointForAngle(angle : CGFloat) -> CGPoint {
        return CGPointMake(0.5 + (sin(angle) / 2.0), 0.5 - cos(angle) / 2.0)
    }
    
    class func endPointForAngle(angle : CGFloat) -> CGPoint {
        return CGPointMake(0.5 - (sin(angle) / 2.0), 0.5 + cos(angle) / 2.0)
    }
    
    class func randomAngle() -> CGFloat {
        // between -pi/2 and +pi/2
        return CGFloat(arc4random_uniform(1000)) / 1000.0 * CGFloat(M_PI) - CGFloat(M_PI_2)
    }
    
}