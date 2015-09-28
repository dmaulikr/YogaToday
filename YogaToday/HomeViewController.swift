/*
* Copyright (c) 2014 Razeware LLC
*
* Permission is hereby granted, free of charge, to any person obtaining a copy
* of this software and associated documentation files (the "Software"), to deal
* in the Software without restriction, including without limitation the rights
* to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
* copies of the Software, and to permit persons to whom the Software is
* furnished to do so, subject to the following conditions:
*
* The above copyright notice and this permission notice shall be included in
* all copies or substantial portions of the Software.
*
* THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
* IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
* FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
* AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
* LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
* OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
* THE SOFTWARE.
*/
//
//  ViewController.swift
//  YogaToday
//
//  Created by Benjamin Jia on 9/21/15.
//  Copyright © 2015 Benjamin Jia. All rights reserved.
//

import UIKit
import YogaTodayKit
import AssetsLibrary

class HomeViewController: UIViewController, JBLineChartViewDataSource, JBLineChartViewDelegate, FBSDKLoginButtonDelegate, FBSDKSharingDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    @IBOutlet weak var loginButton: FBSDKLoginButton!
    @IBOutlet var avatarImageView: UIImageView!
    
    @IBOutlet weak var pointOnDayLabel: UILabel!
    @IBOutlet weak var pointLabel: UILabel!
    @IBOutlet weak var pointChangeLabel: UILabel!
    @IBOutlet weak var dayLabel: UILabel!
    @IBOutlet weak var lineChartView: JBLineChartView!
    
    let ReadPermissions = ["user_about_me", "email"]
    let PublishPermissions = ["publish_actions"]
    let imagePicker = UIImagePickerController()
    let dateFormatter: NSDateFormatter
    
    let dollarNumberFormatter: NSNumberFormatter, prefixedDollarNumberFormatter: NSNumberFormatter
    
    var stats: YogaStats?
    var values: [YogaPoint]?
    var valueDifference: NSNumber? {
        get {
            var difference: NSNumber?
            if (stats != nil && values != nil) {
                if let yesterdaysPoint = YogaService.sharedInstance.yesterdaysValueUsingHistory(values!) {
                    difference = NSNumber(float: stats!.value.floatValue - yesterdaysPoint.value.floatValue)
                }
            }
            
            return difference
        }
    }
    
    required init(coder aDecoder: NSCoder) {
        dateFormatter = NSDateFormatter()
        dateFormatter.dateFormat = "EEE M/d"
        
        dollarNumberFormatter = NSNumberFormatter()
        dollarNumberFormatter.numberStyle = .CurrencyStyle
        dollarNumberFormatter.positivePrefix = ""
        dollarNumberFormatter.negativePrefix = ""
        
        prefixedDollarNumberFormatter = NSNumberFormatter()
        prefixedDollarNumberFormatter.numberStyle = .CurrencyStyle
        prefixedDollarNumberFormatter.positivePrefix = "+"
        prefixedDollarNumberFormatter.negativePrefix = "-"
        
        super.init(coder: aDecoder)!
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        imagePicker.delegate = self
        lineChartView.dataSource = self
        lineChartView.delegate = self
        
        pointOnDayLabel.text = ""
        dayLabel.text = ""
        
        if (FBSDKAccessToken.currentAccessToken() != nil)
        {
            // User is already logged in, do work such as go to next view controller.
            returnUserData()
        }
        else
        {
            loginButton.readPermissions = ReadPermissions
            loginButton.publishPermissions = PublishPermissions
        }
    }
    
    override func viewWillAppear(animated: Bool)  {
        super.viewWillAppear(animated)
        
        fetchPoints{ error in
            if error == nil {
                self.updatePointLabel()
                self.updatePointChangeLabel()
                self.updatePointHistoryLineChart()
            }
        }
    }
    
    override func viewWillTransitionToSize(size: CGSize, withTransitionCoordinator coordinator: UIViewControllerTransitionCoordinator) {
        coordinator.animateAlongsideTransition(nil) { _ in
            self.lineChartView.reloadData()
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    // MARK: - JBLineChartView
    
    func fetchPoints(completion: (error: NSError?) -> ()) {
        YogaService.sharedInstance.getStats { stats, error in
            YogaService.sharedInstance.getHistoryInUSDForPast30Days { values, error in
                dispatch_async(dispatch_get_main_queue()) {
                    self.values = values
                    self.stats = stats
                    completion(error: error)
                }
            }
        }
    }
    
    func updatePointLabel() {
        self.pointLabel.text =  pointLabelString()
    }
    
    func updatePointChangeLabel() {
        let stringAndColor = pointChangeLabelStringAndColor()
        pointChangeLabel.textColor = stringAndColor.color
        pointChangeLabel.text = stringAndColor.string
    }
    
    func updatePointHistoryLineChart() {
        if let points = values {
            let pointsNSArray = points as NSArray
            let maxPoint = pointsNSArray.valueForKeyPath("@max.value") as! NSNumber
            lineChartView.maximumValue = CGFloat(maxPoint.floatValue * 1.02)
            lineChartView.reloadData()
        }
    }
    
    func pointLabelString() -> (String) {
        return dollarNumberFormatter.stringFromNumber(stats?.value ?? 0) ?? "0"
    }
    
    func pointChangeLabelStringAndColor() -> (string: String, color: UIColor) {
        var string: String?
        var color: UIColor?
        
        if let pointDifference = valueDifference {
            if (pointDifference.floatValue > 0) {
                color = UIColor.greenColor()
            } else {
                color = UIColor.redColor()
            }
            
            string = prefixedDollarNumberFormatter.stringFromNumber(pointDifference)
        }
        
        return (string ?? "", color ?? UIColor.blueColor())
    }
    
    // MARK: - JBLineChartViewDataSource & JBLineChartViewDelegate
    
    func numberOfLinesInLineChartView(lineChartView: JBLineChartView!) -> UInt {
        return 1
    }
    
    func lineChartView(lineChartView: JBLineChartView!, numberOfVerticalValuesAtLineIndex lineIndex: UInt) -> UInt {
        var numberOfValues = 0
        if let points = values {
            numberOfValues = points.count
        }
        
        return UInt(numberOfValues)
    }
    
    func lineChartView(lineChartView: JBLineChartView!, verticalValueForHorizontalIndex horizontalIndex: UInt, atLineIndex lineIndex: UInt) -> CGFloat {
        var value: CGFloat = 0.0
        if let points = values {
            let point = points[Int(horizontalIndex)]
            value = CGFloat(point.value.floatValue)
        }
        
        return value
    }
    
    func lineChartView(lineChartView: JBLineChartView!, widthForLineAtLineIndex lineIndex: UInt) -> CGFloat {
        return 2.0
    }
    
    func lineChartView(lineChartView: JBLineChartView!, colorForLineAtLineIndex lineIndex: UInt) -> UIColor! {
        return UIColor(red: 0.17, green: 0.49, blue: 0.82, alpha: 1.0)
    }
    
    func verticalSelectionWidthForLineChartView(lineChartView: JBLineChartView!) -> CGFloat {
        return 1.0;
    }
    
    func updatePointOnDayLabel(point: YogaPoint) {
        pointOnDayLabel.text = dollarNumberFormatter.stringFromNumber(point.value)
    }
    
    func updateDayLabel(point: YogaPoint) {
        dayLabel.text = dateFormatter.stringFromDate(point.time)
    }
    
    // MARK: - JBLineChartViewDataSource & JBLineChartViewDelegate
    
    func lineChartView(lineChartView: JBLineChartView!, didSelectLineAtIndex lineIndex: UInt, horizontalIndex: UInt) {
        if let points = values {
            let point = points[Int(horizontalIndex)]
            updatePointOnDayLabel(point)
            updateDayLabel(point)
        }
    }
    
    func didUnselectLineInLineChartView(lineChartView: JBLineChartView!) {
        pointOnDayLabel.text = ""
        dayLabel.text = ""
    }
    
    // MARK: - Facebook Delegate Methods
    
    func loginButton(loginButton: FBSDKLoginButton!, didCompleteWithResult result: FBSDKLoginManagerLoginResult!, error: NSError!) {
        print("User Logged In")
        
        if ((error) != nil)
        {
            // Process error
        }
        else if result.isCancelled {
            // Handle cancellations
        }
        else {
            // If you ask for multiple permissions at once, you
            // should check if specific permissions missing
            if result.grantedPermissions.contains("email")
            {
                // Do work
                returnUserData()
            }
        }
    }
    
    func loginButtonDidLogOut(loginButton: FBSDKLoginButton!) {
        print("User Logged Out")
    }
    
    func returnUserData()
    {
        let graphRequest : FBSDKGraphRequest = FBSDKGraphRequest(graphPath: "me?fields=id,name,email,picture", parameters: nil)
        graphRequest.startWithCompletionHandler({ (connection, result, error) -> Void in
            
            if ((error) != nil)
            {
                // Process error
                print("Error: \(error)")
            }
            else
            {
                print("fetched user: \(result)")
                let userName : String = result.valueForKey("name") as! String
                print("User Name is: \(userName)")
                let userEmail : String = result.valueForKey("email") as! String
                print("User Email is: \(userEmail)")
                let userAvatar : String = result.valueForKey("picture")?.valueForKey("data")?.valueForKey("url") as! String
                print("User Avatar is: \(userAvatar)")
                
                YogaService.sharedInstance.loadImageFromPath(userAvatar, completion: { image, error in
                    if image != nil {
                        self.avatarImageView.image = image
                    }
                })
            }
        })
    }
    
    // MARK: - Facebook Sharing Delegate
    
    @IBAction func sharePressed(sender: AnyObject) {
        let optionMenu = UIAlertController(title: nil, message: "Choose Sharing Option", preferredStyle: .ActionSheet)
        
        let shareLinkAction = UIAlertAction(title: "Link", style: .Default, handler:
            {
                (alert: UIAlertAction!) -> Void in
                // share a link
                let linkContent: FBSDKShareLinkContent = FBSDKShareLinkContent()
                linkContent.contentTitle = "TUTORIALS FOR DEVELOPERS & GAMERS"
                linkContent.contentURL = NSURL(string: "http://www.raywenderlich.com")
        
                FBSDKShareDialog.showFromViewController(self, withContent: linkContent, delegate: self)
        })
        
        let sharePhotosAction = UIAlertAction(title: "Photos", style: .Default, handler:
            {
                (alert: UIAlertAction!) -> Void in
                self.imagePicker.allowsEditing = false
                self.imagePicker.sourceType = .PhotoLibrary
                
                self.presentViewController(self.imagePicker, animated: true, completion: nil)
        })
        
        let shareVideoAction = UIAlertAction(title: "Video", style: .Default, handler:
            {
                (alert: UIAlertAction!) -> Void in
                self.imagePicker.allowsEditing = false
                self.imagePicker.sourceType = .PhotoLibrary
                
                if let availableMediaTypes = UIImagePickerController.availableMediaTypesForSourceType(.PhotoLibrary) {
                    self.imagePicker.mediaTypes = availableMediaTypes
                }
                
                self.presentViewController(self.imagePicker, animated: true, completion: nil)
        })
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .Cancel, handler:
            {
                (alert: UIAlertAction!) -> Void in
        })
        
        optionMenu.addAction(shareLinkAction)
        optionMenu.addAction(sharePhotosAction)
        optionMenu.addAction(shareVideoAction)
        optionMenu.addAction(cancelAction)
        
        self.presentViewController(optionMenu, animated: true, completion: nil)
    }
    
    func sharer(sharer: FBSDKSharing!, didCompleteWithResults results: [NSObject : AnyObject]!) {
        print("Shared: \(results.description)")
    }
    
    func sharer(sharer: FBSDKSharing!, didFailWithError error: NSError!) {
        print("Failed when sharing: \(error.localizedDescription).")
    }
    
    func sharerDidCancel(sharer: FBSDKSharing!) {
        print("Cancelled sharing.")
    }
    
    // MARK: - UIImagePickerControllerDelegate
    
    func imagePickerController(picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : AnyObject]) {
        if let pickedImage = info[UIImagePickerControllerOriginalImage] as? UIImage {
            self.avatarImageView.image = pickedImage
            
            // share photos
            let photo: FBSDKSharePhoto = FBSDKSharePhoto(image: self.avatarImageView.image, userGenerated: true)
            let photoContent: FBSDKSharePhotoContent = FBSDKSharePhotoContent()
            photoContent.photos = [photo];
    
            dismissViewControllerAnimated(false, completion: nil)
            
            // share photo by ShareDialog
//            FBSDKShareDialog.showFromViewController(self, withContent: photoContent, delegate: self)
            
            // share photo by Messager
//            FBSDKMessageDialog.showWithContent(photoContent, delegate: nil)
            
            // share photo directly
            FBSDKShareAPI.shareWithContent(photoContent, delegate:self)
        }
        else if let videoURL = info[UIImagePickerControllerReferenceURL] as? NSURL {
            // share a video
            let video: FBSDKShareVideo = FBSDKShareVideo(videoURL: videoURL)
            let videoContent: FBSDKShareVideoContent = FBSDKShareVideoContent()
            videoContent.video = video;
    
            dismissViewControllerAnimated(false, completion: nil)
            
            if (FBSDKAccessToken.currentAccessToken() != nil && FBSDKAccessToken.currentAccessToken().hasGranted("publish_actions")) {
                    //            FBSDKShareDialog.showFromViewController(self, withContent: videoContent, delegate: self)
                FBSDKShareAPI.shareWithContent(videoContent, delegate:self)
            } else {
                let loginManager = FBSDKLoginManager()
                loginManager.logInWithPublishPermissions(PublishPermissions, fromViewController: self, handler: {
                    _, _ in
                    FBSDKShareAPI.shareWithContent(videoContent, delegate:self)
                })
            }
        }
        
        dismissViewControllerAnimated(true, completion: nil)
    }
    
    func imagePickerControllerDidCancel(picker: UIImagePickerController) {
        dismissViewControllerAnimated(true, completion: nil)
    }
}

