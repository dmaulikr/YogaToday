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

class HomeViewController: UIViewController, JBLineChartViewDataSource, JBLineChartViewDelegate {
    
    @IBOutlet weak var pointOnDayLabel: UILabel!
    @IBOutlet weak var pointLabel: UILabel!
    @IBOutlet weak var pointChangeLabel: UILabel!
    @IBOutlet weak var dayLabel: UILabel!
    @IBOutlet weak var lineChartView: JBLineChartView!
    
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
        
        lineChartView.dataSource = self
        lineChartView.delegate = self
        
        pointOnDayLabel.text = ""
        dayLabel.text = ""
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
}

