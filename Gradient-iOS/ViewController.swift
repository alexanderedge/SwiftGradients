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

enum AppState {
    case Idle
    case Saving
    case Saved
}

enum Corner {
    case TopLeft
    case TopRight
    case BottomLeft
    case BottomRight
}

extension NSURL {
    
    convenience init?(twitterUsername : String) {
        if UIApplication.sharedApplication().canOpenURL(NSURL(string: "tweetbot://")!) {
            self.init(string: "tweetbot:///user_profile/\(twitterUsername)" )
        } else if UIApplication.sharedApplication().canOpenURL(NSURL(string: "twitterrific://")!) {
            self.init(string: "twitterrific:///profile?screen_name=\(twitterUsername)" )
        } else if UIApplication.sharedApplication().canOpenURL(NSURL(string: "twitter://")!) {
            self.init(string: "twitter://user?screen_name=\(twitterUsername)" )
        } else {
            self.init(string: "https://twitter.com/\(twitterUsername)")
        }
    }

}

extension UIView {
    
    func cornerClosestToPoint(point: CGPoint) -> Corner {
        if point.x > CGRectGetMidX(self.bounds) {
            // right
            if point.y > CGRectGetMidY(self.bounds) {
                return .BottomRight
            } else {
                return .TopRight
            }
        } else {
            // left
            if point.y > CGRectGetMidY(self.bounds) {
                return .BottomLeft
            } else {
                return .TopLeft
            }
        }
    }
    
    private func springAnimationDuration () -> NSTimeInterval {
        return 0.4
    }
    
    private func fadeAnimationDuration () -> NSTimeInterval {
        return 0.5
    }
    
    private func animationDamping () -> CGFloat {
        return 0.8
    }
    
    private func animationInitialSpringVelocity() -> CGFloat {
        return 1.0
    }
    
    func grow(completion : ((Bool) -> Void)?) {
        self.transform = CGAffineTransformMakeScale(0.01, 0.01)
        UIView.animateWithDuration(springAnimationDuration(), delay: 0.0, usingSpringWithDamping: animationDamping(), initialSpringVelocity: animationInitialSpringVelocity(), options: .BeginFromCurrentState, animations: { () -> Void in
            self.transform = CGAffineTransformIdentity
            }, completion: completion)
    }
    
    func shrink(completion : ((Bool) -> Void)?) {
        UIView.animateWithDuration(springAnimationDuration(), delay: 0.0, usingSpringWithDamping: animationDamping(), initialSpringVelocity: animationInitialSpringVelocity(), options: .BeginFromCurrentState, animations: { () -> Void in
            self.transform = CGAffineTransformMakeScale(0.01, 0.01)
            }, completion: completion)
    }
    
    func fadeIn(completion : ((Bool) -> Void)?) {
        self.alpha = 0
        UIView.animateWithDuration(fadeAnimationDuration(), delay: 0.0, options: .BeginFromCurrentState, animations: { () -> Void in
            self.alpha = 1
            }, completion: completion)
    }
    
    func fadeOut(completion : ((Bool) -> Void)?) {
        self.alpha = 1
        UIView.animateWithDuration(fadeAnimationDuration(), delay: 0.0, options: .BeginFromCurrentState, animations: { () -> Void in
            self.alpha = 0
            }, completion: completion)
    }
}

class ViewController: UIViewController, UIScrollViewDelegate, UIGestureRecognizerDelegate {
    
    lazy private var scrollView : UIScrollView = {
        var scrollView = UIScrollView(frame: CGRectZero)
        scrollView.autoresizingMask = .FlexibleWidth | .FlexibleHeight
        scrollView.maximumZoomScale = CGFloat.max
        scrollView.bouncesZoom = false
        scrollView.bounces = false
        scrollView.showsHorizontalScrollIndicator = false
        scrollView.showsVerticalScrollIndicator = false
        scrollView.delegate = self
        return scrollView
    }()
    
    lazy private var gradientView : GradientView = {
        let gradientView = GradientView(frame: CGRectZero)
        gradientView.autoresizingMask = .FlexibleWidth | .FlexibleHeight
        return gradientView
    }()
    
    private var state : AppState = .Idle
    private var colourWheel : ColourWheel?
    private var instructions : UILabel?
    private var credits : UITextView?
    private var creditsShown : Bool = false
    private var infoButton : UIButton?
    private var saveIndicator : UIButton?
    
    // changing colours
    private var startAngle : CGFloat = 0 // angle of touch when the long-press occurs
    private var startColour : UIColor? // colour before change
    private var anchorPoint : CGPoint = CGPointZero // the corner which we're anchored to
    private var colourToChange : Int = 0 // the position (0 or 1) of the gradient colour to change
    
    // MARK: lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.scrollView.frame = self.view.bounds
        self.gradientView.frame = self.scrollView.bounds
        self.scrollView.addSubview(self.gradientView)
        self.view.addSubview(self.scrollView)

        let rotate = UIRotationGestureRecognizer(target: self, action: "handleRotation:")
        rotate.delegate = self
        self.view.addGestureRecognizer(rotate)
        
        let longPress = UILongPressGestureRecognizer(target: self, action: "handleLongPress:")
        longPress.delegate = self;
        self.view.addGestureRecognizer(longPress)
        
        let tap = UITapGestureRecognizer(target: self, action: "handleTap:")
        tap.requireGestureRecognizerToFail(longPress)
        self.view.addGestureRecognizer(tap)
        
        
    }
    
    func viewForZoomingInScrollView(scrollView: UIScrollView!) -> UIView! {
        if self.state == .Idle {
            return self.gradientView
        } else {
            return nil
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func prefersStatusBarHidden() -> Bool {
        return true;
    }
    
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        // add instructions
        let label = UILabel(frame: self.view.bounds)
        label.autoresizingMask = .FlexibleTopMargin | .FlexibleLeftMargin | .FlexibleRightMargin | .FlexibleBottomMargin
        label.backgroundColor = UIColor.blackColor()
        label.numberOfLines = 0
        label.font = UIFont(name: "HelveticaNeue-Thin", size: 24)
        label.userInteractionEnabled = true
        var paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.alignment = .Center
        paragraphStyle.lineHeightMultiple = 2
        label.attributedText = NSAttributedString(string: NSLocalizedString("instructions", comment: "app instructions").uppercaseStringWithLocale(NSLocale.currentLocale()), attributes:[NSForegroundColorAttributeName : UIColor.whiteColor(), NSParagraphStyleAttributeName : paragraphStyle])
        self.view.addSubview(label)
        self.instructions = label;
        
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        self.becomeFirstResponder()
        if let label = self.instructions {
            UIView.animateWithDuration(0.5, delay: 2, options: nil, animations: { () -> Void in
                label.alpha = 0
                }) { (finished : Bool) -> Void in
                    label.removeFromSuperview()
                    self.instructions = nil
            }
        }
    }
    
    override func viewWillDisappear(animated: Bool) {
        self.resignFirstResponder()
        super.viewWillDisappear(animated)
    }
    
    private func reset() {
        self.hideSaveIndicator()
        self.hideInfoButton()
        self.hideCredits()
        self.state = .Idle
    }
    
    override func motionBegan(motion: UIEventSubtype, withEvent event: UIEvent) {
        if motion == .MotionShake {
            self.reset()
            self.gradientView.changeGradient(true)
            AudioServicesPlaySystemSound(SystemSoundID(kSystemSoundID_Vibrate))
        }
        super.motionBegan(motion, withEvent: event)
    }
    
    // MARK: Gesture recognisers
    
    func gestureRecognizerShouldBegin(gestureRecognizer: UIGestureRecognizer) -> Bool {
        return self.state == .Idle ? true : false
    }
    
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
        switch self.state {
        case .Idle:
            self.saveGradient()
        case .Saved:
            if creditsShown {
                self.hideCredits()
            } else {
                self.reset()
            }
        case .Saving:
            return // save in progress... do nothing
        }
    }

    private func transformForCorner(corner : Corner) -> CGAffineTransform {
        switch corner {
        case .TopLeft:
            return CGAffineTransformIdentity
        case .TopRight:
            return CGAffineTransformMakeRotation(CGFloat(M_PI))
        case .BottomLeft:
            return CGAffineTransformIdentity
        case .BottomRight:
            return CGAffineTransformMakeRotation(CGFloat(M_PI))
        }
    }
    
    private func anchorPointForCorner(corner : Corner, inView view : UIView, inset : CGFloat = 0) -> CGPoint {
        switch corner {
        case .TopLeft:
            return CGPointMake(inset, inset)
        case .TopRight:
            return CGPointMake(CGRectGetMaxX(view.bounds) - inset, inset)
        case .BottomLeft:
            return CGPointMake(inset,CGRectGetMaxY(view.bounds) - inset)
        case .BottomRight:
            return CGPointMake(CGRectGetMaxX(view.bounds) - inset,CGRectGetMaxY(view.bounds) - inset)
        }
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
            let closestCorner = self.view.cornerClosestToPoint(touchPoint)
            let anchor = anchorPointForCorner(closestCorner, inView: self.view)
            
            self.anchorPoint = anchor
            
            // calculate which colour to change
            
            let gradientAngle = self.gradientView.rotation
            
            // create a vector through the centre of the screen, at the given angle
            let y = (CGRectGetWidth(self.view.bounds) / 2) * tan(gradientAngle)
            
            let a = CGPointMake(0, (CGRectGetHeight(self.view.bounds) / 2) - y)
            let b = CGPointMake(CGRectGetWidth(self.view.bounds), (CGRectGetHeight(self.view.bounds) / 2) + y)
            
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
            
            // find the angle of the touch point
            // zero is horizontal
            
            let angle = angleOfTouchPoint(touchPoint, fromPoint: anchor)
            
            let colour = self.gradientView.colorAtPosition(self.colourToChange)
            
            var hue : CGFloat = 0
            var saturation : CGFloat = 0
            var brightness : CGFloat = 0
            var alpha : CGFloat = 0
            colour.getHue(&hue, saturation: &saturation, brightness: &brightness, alpha: &alpha)
            
            var wheel = ColourWheel(frame : CGRectMake(0, 0, 200, 200))
            wheel.center = anchorPointForCorner(closestCorner, inView: self.view, inset: 10)
            wheel.saturation = saturation
            wheel.brightness = brightness
            wheel.focalAngle = angle
            wheel.focalHue = hue
            
            let targetTransform = transformForCorner(closestCorner)
            
            wheel.transform = CGAffineTransformConcat(targetTransform, CGAffineTransformMakeScale(0.01, 0.01))
            
            self.view.addSubview(wheel)
            // don't use the -grow method here since we already have a transform
            UIView.animateWithDuration(0.4, delay: 0, usingSpringWithDamping: 0.8, initialSpringVelocity: 1.0, options: nil, animations: { () -> Void in
                wheel.transform = targetTransform
            }, completion: nil)
            
            self.colourWheel = wheel
            self.startAngle = angle
            self.startColour = colour
            
            
        } else if gr.state == .Changed {
          
            // update the gradient with the colour from the wheel
            
            // find the angle from the horizontal from the closest corner
            let angle = angleOfTouchPoint(touchPoint, fromPoint: self.anchorPoint)
            
            let angleChange = angle - self.startAngle
            
            // express the delta in terms of hue
            let hueChange = angleChange / CGFloat(2 * M_PI)
            
            // calculate the new colour
            var newColor = self.startColour!.colorByShiftingHue(hueChange)
            
            self.gradientView.setColor(newColor, atPosition: self.colourToChange)
            
        } else if gr.state == .Ended {
            
            if let view = self.colourWheel {
                UIView.animateWithDuration(0.4, delay: 0, usingSpringWithDamping: 0.8, initialSpringVelocity: 1.0, options: nil, animations: { () -> Void in
                    view.transform = CGAffineTransformConcat(self.colourWheel!.transform, CGAffineTransformMakeScale(0.01, 0.01))
                    }, completion : { (finished : Bool) -> Void in
                        view.removeFromSuperview()
                        self.colourWheel = nil
                })
            }
        }
    }
    
    // MARK: Saving gradients
    
    private func imageFromCurrentGradient() -> UIImage {
        UIGraphicsBeginImageContextWithOptions(self.scrollView.frame.size, true, 0.0)
        self.scrollView.drawViewHierarchyInRect(self.scrollView.frame, afterScreenUpdates: false)
        let screenshot = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        // convert to PNG so that it doesn't save a JPEG (default)
        let pngData = UIImagePNGRepresentation(screenshot)
        return UIImage(data: pngData)!
    }
    
    private func saveGradient () {
        self.state = .Saving
        let gradient = self.imageFromCurrentGradient()
        
        UIImageWriteToSavedPhotosAlbum(gradient, self, "image:didFinishSavingWithError:contextInfo:", nil)
    }
    
    func image(image : UIImage, didFinishSavingWithError error : NSError!, contextInfo : UnsafePointer<Void>) {
        if error != nil {
            // there was a problem saving the gradient
            // just display the activity controller instead
            self.showActivityControllerForImage(image)
            self.state = .Idle
        } else {
            self.state = .Saved
            self.showSaveIndicator()
            self.showInfoButton()
        }
    }
    
    private func showInfoButton () {
        let btn = UIButton(frame: CGRectMake(CGRectGetWidth(self.view.bounds) - 50, 0, 50, 50))
        btn.autoresizingMask = .FlexibleLeftMargin | .FlexibleBottomMargin
        btn.tintColor = UIColor.blackColor().colorWithAlphaComponent(0.6)
        btn.setImage(UIImage(named: "Info")?.imageWithRenderingMode(.AlwaysTemplate), forState: .Normal)
        btn.accessibilityHint = NSLocalizedString("information_hint", comment: "accessibility hint for info button")
        btn.accessibilityLabel = NSLocalizedString("information", comment: "")
        btn.addTarget(self, action: "infoPressed:", forControlEvents: .TouchUpInside)
        self.view.addSubview(btn)
        btn.fadeIn(nil)
        self.infoButton = btn
    }
    
    private func hideInfoButton () {
        if let btn = self.infoButton {
            btn.fadeOut({ (finished : Bool) -> Void in
                btn.removeFromSuperview()
                self.infoButton = nil
            })
        }
    }
    
    private func showSaveIndicator () {
        let btn = UIButton(frame: CGRectMake(0, 0, 100.0, 100.0))
        btn.layer.cornerRadius = 50.0
        btn.backgroundColor = UIColor.blackColor().colorWithAlphaComponent(0.6)
        btn.tintColor = UIColor.whiteColor()
        btn.autoresizingMask = .FlexibleTopMargin | .FlexibleLeftMargin | .FlexibleRightMargin | .FlexibleBottomMargin
        btn.titleLabel?.numberOfLines = 0
        btn.titleLabel?.textAlignment = .Center
        btn.titleLabel?.font = UIFont(name: "HelveticaNeue-Thin", size: 17.0)
        btn.titleLabel?.center = btn.center
        btn.titleLabel?.lineBreakMode = .ByWordWrapping
        
        btn.contentVerticalAlignment = .Center
        btn.setTitle(NSLocalizedString("saved", comment: "gradient saved").uppercaseStringWithLocale(NSLocale.autoupdatingCurrentLocale()), forState: .Normal)
        btn.addTarget(self, action: "sharePressed:", forControlEvents: .TouchUpInside)
        btn.center = self.view.center
        self.view.addSubview(btn)
        
        btn.grow { (finished : Bool) -> () in
            UIView.transitionWithView(btn, duration: 0.5, options: .TransitionCrossDissolve, animations: { () -> Void in
                btn.setTitle(nil, forState: .Normal)
                btn.setImage(UIImage(named: "Action")?.imageWithRenderingMode(.AlwaysTemplate), forState: .Normal)
                }, completion: nil)
        }
        
        self.saveIndicator = btn
        
    }
    
    private func hideSaveIndicator () {
        if let btn = self.saveIndicator {
            btn.shrink { (finished : Bool) -> () in
                btn.removeFromSuperview()
                self.saveIndicator = nil
            }
        }
    }
    
    private func showCredits () {
        self.creditsShown = true
        
        self.infoButton?.hidden = true
        
        let textView = UITextView(frame: self.view.bounds)
        textView.editable = false
        textView.scrollEnabled = false
        textView.autoresizingMask = .FlexibleTopMargin | .FlexibleLeftMargin | .FlexibleRightMargin | .FlexibleBottomMargin
        textView.backgroundColor = UIColor.blackColor()
        textView.textContainer.lineFragmentPadding = 0
        textView.textContainerInset = UIEdgeInsetsMake(40, 40, 40, 40)
        textView.linkTextAttributes = [NSUnderlineStyleAttributeName : NSUnderlineStyle.StyleSingle.rawValue]
        
        var paragraphStyle : NSMutableParagraphStyle = NSParagraphStyle.defaultParagraphStyle().mutableCopy() as NSMutableParagraphStyle
        paragraphStyle.alignment = .Center
        paragraphStyle.lineSpacing = 20
        
        var attrs : Dictionary <NSObject,AnyObject> = [NSForegroundColorAttributeName : UIColor.whiteColor(), NSFontAttributeName : UIFont(name: "HelveticaNeue-Thin", size: 24)!, NSParagraphStyleAttributeName : paragraphStyle]
        
        var str : NSString = NSLocalizedString("credits", comment: "app credits")
        var attributedStr = NSMutableAttributedString(string: str, attributes: attrs)
        
        attributedStr.addAttribute(NSLinkAttributeName, value: NSURL(twitterUsername: "byedit")!, range: str.rangeOfString("Nitzan Hermon"))
        attributedStr.addAttribute(NSLinkAttributeName, value: NSURL(twitterUsername: "alexedge")!, range: str.rangeOfString("Alex Edge"))
        
        textView.attributedText = attributedStr
        textView.sizeToFit()
        textView.center = self.view.center
        self.view.addSubview(textView)
        
        self.credits = textView
        
    }
    
    private func hideCredits () {
        self.infoButton?.hidden = false
        self.credits?.removeFromSuperview()
        self.credits = nil
        self.creditsShown = false
    }
    
    func sharePressed (button : UIButton) {
        let gradient = self.imageFromCurrentGradient()
        self.showActivityControllerForImage(gradient)
    }
    
    func infoPressed (button : UIButton) {
        if creditsShown {
            self.hideCredits()
        } else {
            self.showCredits()
        }
    }
    
    private func showActivityControllerForImage(image : UIImage) {
        let activityController = UIActivityViewController(activityItems: [image], applicationActivities: nil)
        if activityController.respondsToSelector("popoverPresentationController") && self.saveIndicator != nil {
            activityController.popoverPresentationController?.sourceView = self.saveIndicator!
            activityController.popoverPresentationController?.sourceRect = CGRectInset(self.saveIndicator!.bounds, -10, -10)
        }
        self.presentViewController(activityController, animated: true, completion: nil)
    }
    
}

