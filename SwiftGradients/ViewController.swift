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

class ViewController: UIViewController, UIScrollViewDelegate, UIGestureRecognizerDelegate {
    
    let kInfoButtonSideLength : CGFloat = 44.0;
    let kInfoButtonMargin : CGFloat = 10.0;
    
    @IBOutlet weak var scrollView : UIScrollView!
    @IBOutlet weak var gradientView : GradientView!
    
    lazy var saveIndicator : UIButton = {
        let btn = UIButton(frame: CGRectMake(0, 0, 100.0, 100.0))
        btn.layer.cornerRadius = 50.0
        btn.backgroundColor = UIColor.blackColor().colorWithAlphaComponent(0.6)
        
        btn.titleLabel.numberOfLines = 0
        btn.titleLabel.textAlignment = .Center
        btn.titleLabel.font = UIFont(name: "Avenir Next Condensed Ultra Light", size: 17.0)
        btn.titleLabel.center = btn.center
        btn.titleLabel.lineBreakMode = .ByWordWrapping
        
        btn.contentVerticalAlignment = .Center
        btn.setTitle(NSLocalizedString("saved", comment: "").uppercaseString, forState: .Normal)
        btn.addTarget(self, action: Selector("sharePressed:"), forControlEvents: .TouchUpInside)
        return btn
    }()
    
    func gestureRecognizer(gestureRecognizer: UIGestureRecognizer!, shouldRecognizeSimultaneouslyWithGestureRecognizer otherGestureRecognizer: UIGestureRecognizer!) -> Bool {
        return true
    }
    
    @IBAction func handleRotation(gr : UIRotationGestureRecognizer) {
        if gr.state == .Began {
            gr.rotation = self.gradientView.rotation;
        }
        else if gr.state == .Changed {
            self.gradientView.rotation = gr.rotation
        }
    }
    
    @IBAction func handleTap(gr : UITapGestureRecognizer) {
        if (self.saveIndicator.superview != nil) {
            self.hideSaveIndicator()
        } else {
            self.saveGradient()
        }
    }
    
    func saveGradient () {
        UIGraphicsBeginImageContextWithOptions(self.view.bounds.size, true, 0.0)
        self.view.drawViewHierarchyInRect(self.view.bounds, afterScreenUpdates: false)
        let screenshot = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        // convert to PNG so that it doesn't save a JPEG
        let pngData = UIImagePNGRepresentation(screenshot)
        let gradient = UIImage(data: pngData)
        UIImageWriteToSavedPhotosAlbum(gradient, self, Selector("image:didFinishSavingWithError:contextInfo:"), nil)
    }
    
    func image(image : UIImage, didFinishSavingWithError error : NSError!, contextInfo : UnsafePointer<Void>) {
        
        if error != nil {
            
            var alertController : UIAlertController?
            
            if error.code == ALAssetsLibraryAccessUserDeniedError || error.code == ALAssetsLibraryAccessGloballyDeniedError {
                alertController = UIAlertController(title: NSLocalizedString("unable_to_save", comment: ""), message: NSLocalizedString("cannot_access_photos", comment: ""), preferredStyle: .Alert)
                
            } else {
                alertController = UIAlertController(title: NSLocalizedString("unable_to_save", comment: ""), message: error.localizedDescription, preferredStyle: .Alert)
                
            }
            
            alertController?.addAction(UIAlertAction(title: NSLocalizedString("close", comment: ""), style: .Cancel, handler: nil))
            self.presentViewController(alertController, animated: true, completion: nil)
            
        } else {
            self.showSaveIndicator();
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

    override func motionBegan(motion: UIEventSubtype, withEvent event: UIEvent!) {
        if motion == .MotionShake {
            self.gradientView.changeGradient(true)
            AudioServicesPlaySystemSound(SystemSoundID(kSystemSoundID_Vibrate))
        }
        super.motionBegan(motion, withEvent: event)
    }
    
}

