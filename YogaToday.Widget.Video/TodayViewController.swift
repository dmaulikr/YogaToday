//
//  TodayViewController.swift
//  YogaToday.Widget.Video
//
//  Created by Benjamin Jia on 9/21/15.
//  Copyright © 2015 Benjamin Jia. All rights reserved.
//

import UIKit
import NotificationCenter

class TodayViewController: UIViewController, NCWidgetProviding, UICollectionViewDataSource {
    
    @IBOutlet weak var collectionView: UICollectionView!
    
    let VideoImageTag = 100
    let VideoButtonTag = 101
    
    let videos:[String] = ["Video.Beginner.01", "Video.Beginner.02", "Video.Beginner.03"]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view from its nib.
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func widgetMarginInsetsForProposedMarginInsets(defaultMarginInsets: UIEdgeInsets) -> UIEdgeInsets {
        return UIEdgeInsetsZero;
    }
    
    func widgetPerformUpdateWithCompletionHandler(completionHandler: ((NCUpdateResult) -> Void)) {
        // Perform any setup necessary in order to update the view.

        // If an error is encountered, use NCUpdateResult.Failed
        // If there's no update required, use NCUpdateResult.NoData
        // If there's an update, use NCUpdateResult.NewData

        completionHandler(NCUpdateResult.NewData)
    }
    
    // MARK: -UICollectionView DataSource
    
    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return self.videos.count
    }
    
    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier("YogaVideoIdentifier", forIndexPath: indexPath)
        
        if let vedioImage: UIImageView = cell.viewWithTag(VideoImageTag) as? UIImageView {
            vedioImage.image = UIImage(named: self.videos[indexPath.row])
        }
        
        if let vedioButton: UIButton = cell.viewWithTag(VideoButtonTag) as? UIButton {
            vedioButton.setTitle("Beginner", forState: UIControlState.Normal)
        }
        
        return cell
    }
}
