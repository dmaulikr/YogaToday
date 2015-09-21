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

import Foundation
import Alamofire

public typealias StatsCompletionBlock = (stats: YogaStats?, error: NSError?) -> ()
public typealias HistoryCompletionBlock = (values: [YogaPoint]?, error: NSError?) -> ()

public class YogaService {
    
    let statsCacheKey = "YogaServiceStatsCache"
    let statsCachedDateKey = "YogaServiceStatsCachedDate"
    
    let historyCacheKey = "YogaServiceHistoryCache"
    let historyCachedDateKey = "YogaServiceHistoryCachedDate"
    
    let session: NSURLSession
    
    public class var sharedInstance: YogaService {
        struct Singleton {
            static let instance = YogaService()
        }
        return Singleton.instance
    }
    
    init() {
        let configuration = NSURLSessionConfiguration.defaultSessionConfiguration()
        session = NSURLSession(configuration: configuration)
    }
    
    public func getStats(completion: StatsCompletionBlock) {
        if let cachedStats: YogaStats = getCachedStats() {
            completion(stats: cachedStats, error: nil)
            return
        }
        
        Alamofire.request(.GET, "https://blockchain.info/stats?format=json")
            .responseJSON { _, _, result in
                print("Success: \(result.isSuccess)")
                print("Response result: \(result.value)")

                if result.isSuccess {
                    if let jsonData = result.value {
                        let json = JSON(jsonData)
                        let stats: YogaStats = YogaStats(fromJSON: json)
                        self.cacheStats(stats)

                        dispatch_async(dispatch_get_main_queue()) {
                            completion(stats: stats, error: nil)
                        }
                    } else {
                        completion(stats: nil, error: nil)
                    }
                } else {
                    completion(stats: nil, error: nil)
                }
        }
    }
    
    public func getHistoryInUSDForPast30Days(completion: HistoryCompletionBlock) {
        if let cachedValues: [YogaPoint] = getCachedHistory() {
            completion(values: cachedValues, error: nil)
            return
        }
        
        Alamofire.request(.GET, "https://blockchain.info/charts/market-price?timespan=30days&format=json")
            .responseJSON { _, _, result in
                print("Success: \(result.isSuccess)")
                print("Response result: \(result.value)")
                
                var values = [YogaPoint]()
                
                if result.isSuccess {
                    if let jsonData = result.value {
                        let json = JSON(jsonData)
                        let pointValues = json["values"]
                        
                        for (_, pointDictionary):(String, JSON) in pointValues {
                            let point = YogaPoint(fromJSON: pointDictionary)
                            values.append(point)
                        }
                        
                        self.cacheHistory(values)
                        
                        dispatch_async(dispatch_get_main_queue()) {
                            completion(values: values, error: nil)
                        }
                    } else {
                        completion(values: values, error: nil)
                    }
                } else {
                    completion(values: values, error: nil)
                }
        }
    }
    
    public func yesterdaysValueUsingHistory(History: Array<YogaPoint>) -> (YogaPoint?) {
        var yesterdaysValue: YogaPoint?
        
        for value in Array(History.reverse()) {
            if (value.time.isYesterday()) {
                yesterdaysValue = value
                break;
            }
        }
        
        return yesterdaysValue
    }
    
    func loadCachedDataForKey(key: String, cachedDateKey: String) -> AnyObject? {
        var cachedValue: AnyObject?
        
        if let cachedDate = NSUserDefaults.standardUserDefaults().valueForKey(cachedDateKey) as? NSDate {
            let timeInterval = NSDate().timeIntervalSinceDate(cachedDate)
            if (timeInterval < 60*5) {
                let cachedData = NSUserDefaults.standardUserDefaults().valueForKey(key) as? NSData
                if cachedData != nil {
                    cachedValue = NSKeyedUnarchiver.unarchiveObjectWithData(cachedData!)
                }
            }
        }
        
        
        return cachedValue
    }
    
    func getCachedStats() -> YogaStats? {
        let stats = loadCachedDataForKey(statsCacheKey, cachedDateKey: statsCachedDateKey) as? YogaStats
        return stats
    }
    
    func getCachedHistory() -> [YogaPoint]? {
        let values = loadCachedDataForKey(historyCacheKey, cachedDateKey: historyCachedDateKey) as? [YogaPoint]
        return values
    }
    
    func cacheStats(stats: YogaStats) {
        print(stats, terminator: "")
        let statsData = NSKeyedArchiver.archivedDataWithRootObject(stats)
        
        NSUserDefaults.standardUserDefaults().setValue(statsData, forKey: statsCacheKey)
        NSUserDefaults.standardUserDefaults().setValue(NSDate(), forKey: statsCachedDateKey)
    }
    
    func cacheHistory(history: [YogaPoint]) {
        let pointData = NSKeyedArchiver.archivedDataWithRootObject(history)
        
        NSUserDefaults.standardUserDefaults().setValue(pointData, forKey: historyCacheKey)
        NSUserDefaults.standardUserDefaults().setValue(NSDate(), forKey: historyCachedDateKey)
    }
}
