//  ViewController.swift
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
import AudioToolbox
import AssetsLibrary

enum GradientSaveState {
    case Idle
    case Saving
    case Saved
}

extension UIView {
    
    func animationDuration () -> NSTimeInterval {
        return 0.5
    }
    
    func animationDamping () -> CGFloat {
        return 0.6
    }
    
    func animationInitialSpringVelocity() -> CGFloat {
        return 0.2
    }
    
    func grow(completion : ((Bool) -> ())?) {
        self.transform = CGAffineTransformMakeScale(0.01, 0.01)
        UIView.animateWithDuration(animationDuration(), delay: 0.0, usingSpringWithDamping: animationDamping(), initialSpringVelocity: animationInitialSpringVelocity(), options: .BeginFromCurrentState, animations: { () -> Void in
            self.transform = CGAffineTransformIdentity
            }, completion: completion)
    }
    
    func shrink(completion : ((Bool) -> ())?) {
        UIView.animateWithDuration(animationDuration(), delay: 0.0, usingSpringWithDamping: animationDamping(), initialSpringVelocity: animationInitialSpringVelocity(), options: .BeginFromCurrentState, animations: { () -> Void in
        self.transform = CGAffineTransformMakeScale(0.01, 0.01)
        }, completion: completion)
    }
}

class ViewController: UIViewController, UIScrollViewDelegate, UIGestureRecognizerDelegate {
    
    var saveState : GradientSaveState = .Idle
    var scrollView : UIScrollView
    var gradientView : GradientView
    var colourWheel : ColourWheel?
    
    // changing colours
    var startAngle : CGFloat = 0 // angle of touch when the long-press occurs
    var startColour : UIColor? // colour before change
    var anchorPoint : CGPoint = CGPointZero // the corner which we're anchored to
    var colourToChange : Int = 0 // the position (0 or 1) of the gradient colour to change
    
    override init() {
        var scrollView = UIScrollView(frame: CGRectZero)
        scrollView.maximumZoomScale = CGFloat.max
        scrollView.bouncesZoom = false
        scrollView.bounces = false
        scrollView.showsHorizontalScrollIndicator = false
        scrollView.showsVerticalScrollIndicator = false
        self.scrollView = scrollView
        
        var gradientView = GradientView(frame: CGRectZero)
        scrollView.addSubview(gradientView)
        self.gradientView = gradientView
        
        super.init(nibName:nil,bundle:nil)
    }

    required init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    lazy var saveIndicator : UIButton = {
        let btn = UIButton(frame: CGRectMake(0, 0, 100.0, 100.0))
        btn.layer.cornerRadius = 50.0
        btn.backgroundColor = UIColor.blackColor().colorWithAlphaComponent(0.6)
        
        btn.titleLabel?.numberOfLines = 0
        btn.titleLabel?.textAlignment = .Center
        btn.titleLabel?.font = UIFont(name: "Avenir Next Condensed Ultra Light", size: 17.0)
        btn.titleLabel?.center = btn.center
        btn.titleLabel?.lineBreakMode = .ByWordWrapping
        
        btn.contentVerticalAlignment = .Center
        btn.setTitle(NSLocalizedString("saved", comment: "").uppercaseString, forState: .Normal)
        btn.addTarget(self, action: "sharePressed:", forControlEvents: .TouchUpInside)
        return btn
    }()
    
    func gestureRecognizer(gestureRecognizer: UIGestureRecognizer!, shouldRecognizeSimultaneouslyWithGestureRecognizer otherGestureRecognizer: UIGestureRecognizer!) -> Bool {
        return true
    }
    
    func handleRotation(gr : UIRotationGestureRecognizer) {
        if gr.state == .Began {
            gr.rotation = self.gradientView.rotation;
        } else if gr.state == .Changed {
            self.gradientView.rotation = gr.rotation
        }
    }
    
    func handleTap(gr : UITapGestureRecognizer) {
        switch self.saveState {
            case .Idle:
                self.saveGradient()
            case .Saved:
                self.hideSaveIndicator()
            case .Saving:
                return // save in progress... do nothing
        }
    }
    
    private func cornerClosestToPoint(point: CGPoint, inView view: UIView) -> CGPoint {
        var cornerPoint = CGPointZero
        if point.x > CGRectGetMidX(view.bounds) {
            cornerPoint.x = CGRectGetMaxX(view.bounds)
        }
        if point.y > CGRectGetMidY(view.bounds) {
            cornerPoint.y = CGRectGetMaxY(view.bounds)
        }
        return cornerPoint
    }
    
    private func angleOfTouchPoint(point: CGPoint, fromPoint: CGPoint) -> CGFloat {
        // angle from the horizontal is given by: theta = tan-1 (y/x)
        return atan((point.y - fromPoint.y) / (point.x - fromPoint.x))
    }
    
    private func crossProduct(a : CGPoint, b : CGPoint, c : CGPoint) -> CGFloat {
        return (b.x - a.x) * (c.y - a.y) - (b.y - a.y) * (c.x - a.x)
    }

    func handleLongPress(gr: UILongPressGestureRecognizer) {
        
        let touchPoint = gr.locationInView(gr.view)
        
        if gr.state == .Began {
            
            // find the corner closest to the touch point
            let closestCorner = cornerClosestToPoint(touchPoint, inView: self.view)
            
            self.anchorPoint = closestCorner
            
            // find the angle of the touch point
            // zero is horizontal
            
            let angle = angleOfTouchPoint(touchPoint, fromPoint: closestCorner)
            
            let colour = self.gradientView.colourAtPoint(touchPoint)
            
            self.startColour = colour
            
            var hue : CGFloat = 0
            var saturation : CGFloat = 0
            var brightness : CGFloat = 0
            var alpha : CGFloat = 0
            colour.getHue(&hue, saturation: &saturation, brightness: &brightness, alpha: &alpha)
            
            var wheel = ColourWheel(frame : CGRectMake(0, 0, 200, 200))
            wheel.center = closestCorner
            wheel.saturation = saturation
            wheel.brightness = brightness
            wheel.startHue = hue
            wheel.startAngle = angle
            
            self.view.addSubview(wheel)
            wheel.grow(nil)
            
            self.colourWheel = wheel
            self.startAngle = angle
            self.startColour = colour
            
            // calculate which colour to change
            
            let gradientAngle = self.gradientView.rotation
            NSLog("gradient is at \(gradientAngle)")
            
            // create a vector through the centre of the screen, at the given angle
            let y = (CGRectGetWidth(self.view.bounds) / 2) * tan(gradientAngle)
            
            let a = CGPointMake(0, (CGRectGetHeight(self.view.bounds) / 2) - y)
            let b = CGPointMake(CGRectGetWidth(self.view.bounds), (CGRectGetHeight(self.view.bounds) / 2) + y)
            
            NSLog("vector runs from \(a) to \(b)")
            
            if gradientAngle > CGFloat(-M_PI_2) && gradientAngle < CGFloat(M_PI_2) {
                if crossProduct(a, b: b, c: touchPoint) > 0 {
                    self.colourToChange = 1
                } else {
                    self.colourToChange = 0
                }
            } else {
                
                if crossProduct(a, b: b, c: touchPoint) > 0 {
                    self.colourToChange = 0
                } else {
                    self.colourToChange = 1
                }
            }
            
        } else if gr.state == .Changed {
          
            // update the gradient with the colour from the wheel
            
            // find the angle from the horizontal from the closest corner
            let angle = angleOfTouchPoint(touchPoint, fromPoint: self.anchorPoint)
            
            let angleChange = angle - self.startAngle
            
            // express the delta in terms of hue
            let hueChange = angleChange / CGFloat(M_PI_2)
            
            // calculate the new colour
            var newColor = self.startColour!.colorByShiftingHue(hueChange)
            
            self.gradientView.setColor(newColor, atPosition: self.colourToChange)
            
        } else if gr.state == .Ended {
            
            self.colourWheel?.shrink({ (finished : Bool) -> () in
                self.colourWheel?.removeFromSuperview()
                self.colourWheel = nil
            })
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.scrollView.frame = self.view.bounds
        self.gradientView.frame = self.scrollView.bounds;
        self.view.addSubview(self.scrollView)
        
        self.scrollView.delegate = self
        
        let rotate = UIRotationGestureRecognizer(target: self, action: "handleRotation:")
        rotate.delegate = self
        self.view.addGestureRecognizer(rotate)
        
        let tap = UITapGestureRecognizer(target: self, action: "handleTap:")
        self.view.addGestureRecognizer(tap)
        
        let longPress = UILongPressGestureRecognizer(target: self, action: "handleLongPress:")
        self.view.addGestureRecognizer(longPress)
        
    }
    
    func saveGradient () {
        self.saveState = .Saving
        UIGraphicsBeginImageContextWithOptions(self.view.bounds.size, true, 0.0)
        self.view.drawViewHierarchyInRect(self.view.bounds, afterScreenUpdates: false)
        let screenshot = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        // convert to PNG so that it doesn't save a JPEG
        let pngData = UIImagePNGRepresentation(screenshot)
        let gradient = UIImage(data: pngData)
        UIImageWriteToSavedPhotosAlbum(gradient, self, "image:didFinishSavingWithError:contextInfo:", nil)
    }
    
    func image(image : UIImage, didFinishSavingWithError error : NSError!, contextInfo : UnsafePointer<Void>) {
        if error != nil {
            var alertController : UIAlertController?
            
            if error.code == ALAssetsLibraryAccessUserDeniedError || error.code == ALAssetsLibraryAccessGloballyDeniedError {
                alertController = UIAlertController(title: NSLocalizedString("unable_to_save", comment: ""), message: NSLocalizedString("cannot_access_photos", comment: ""), preferredStyle: .Alert)
                
            } else {
                alertController = UIAlertController(title: NSLocalizedString("unable_to_save", comment: ""), message: error.localizedDescription, preferredStyle: .Alert)
            }
            
            alertController!.addAction(UIAlertAction(title: NSLocalizedString("close", comment: ""), style: .Cancel, handler: nil))
            self.presentViewController(alertController!, animated: true, completion: { () -> Void in
                self.saveState = .Idle
            })
            
        } else {
            self.saveState = .Saved
            self.showSaveIndicator()
        }
    }
    
    func showSaveIndicator () {
        let btn = self.saveIndicator
        btn.center = self.view.center
        btn.transform = CGAffineTransformMakeScale(0.01, 0.01)
        self.view.addSubview(btn)
        btn.grow(nil)
    }
    
    func hideSaveIndicator () {
        let btn = self.saveIndicator
        btn.shrink { (finished : Bool) -> () in
            btn.removeFromSuperview()
            self.saveState = .Idle
        }
    }
    
    func sharePressed (button : UIButton) {
        
    }
    
    func viewForZoomingInScrollView(scrollView: UIScrollView!) -> UIView! {
        return self.gradientView
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func prefersStatusBarHidden() -> Bool {
        return true;
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        self.becomeFirstResponder()
    }
    
    override func viewWillDisappear(animated: Bool) {
        self.resignFirstResponder()
        super.viewWillDisappear(animated)
    }

    override func motionBegan(motion: UIEventSubtype, withEvent event: UIEvent) {
        if motion == .MotionShake {
            self.gradientView.changeGradient(true)
            AudioServicesPlaySystemSound(SystemSoundID(kSystemSoundID_Vibrate))
        }
        super.motionBegan(motion, withEvent: event)
    }
    
}

