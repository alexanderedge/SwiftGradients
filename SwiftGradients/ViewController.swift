//
//  ViewController.swift
//  SwiftGradients
//
//  Created by Alexander G Edge on 31/08/2014.
//  Copyright (c) 2014 Alexander Edge Ltd. All rights reserved.
//

import UIKit
import AudioToolbox
import AssetsLibrary

enum GradientSaveState {
    case Idle
    case Saving
    case Saved
}

class ViewController: UIViewController, UIScrollViewDelegate, UIGestureRecognizerDelegate {
    
    var saveState : GradientSaveState = .Idle
    var scrollView : UIScrollView
    var gradientView : GradientView
    
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
        UIView.animateWithDuration(0.5, delay: 0.0, usingSpringWithDamping: 0.6, initialSpringVelocity: 0.2, options: nil, animations: { () -> Void in
            btn.transform = CGAffineTransformIdentity
            }, completion: nil)
    }
    
    func hideSaveIndicator () {
        let btn = self.saveIndicator
        UIView.animateWithDuration(0.5, delay: 0.0, usingSpringWithDamping: 0.6, initialSpringVelocity: 0.2, options: nil, animations: { () -> Void in
            btn.transform = CGAffineTransformMakeScale(0.01, 0.01)
            }, completion: { (finished : Bool) -> Void in
                btn.removeFromSuperview();
                self.saveState = .Idle
        })
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

