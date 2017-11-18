//
//  RulerAppleWatchHelper.swift
//  BeaverRuler
//
//  Created by user on 11/18/17.
//  Copyright © 2017 Sasha. All rights reserved.
//

import Foundation
import WatchConnectivity

class RulerAppleWatchHelper: NSObject, WCSessionDelegate {
    
    var rulerScreen: ViewController!
    var lastMessage: CFAbsoluteTime = 0
    
    func sessionDidBecomeInactive(_ session: WCSession) {
        
    }
    
    func sessionDidDeactivate(_ session: WCSession) {
        
    }
    
    func session(_ session: WCSession, didReceiveMessage message: [String : Any]) {
        if let reference = message["Message"] as? String {
            if reference == "makeScreenshot" {
                DispatchQueue.main.async {
                    self.rulerScreen.takeScreenshot()
                }
                return
            }
            
            if reference == "makePoint" {
                DispatchQueue.main.async {
                    self.rulerScreen.nextPointTap()
                }
                return
            }
            
            if reference == "donePressed" {
                DispatchQueue.main.async {
                    self.rulerScreen.finishPolygonPressed("")
                }
                return
            }
        }
    }
    
    func session(_ session: WCSession, didReceiveMessage message: [String : Any], replyHandler: @escaping ([String : Any]) -> Void) {
        if let reference = message["Message"] as? String {
            
            if reference == "userMeasures" {
                DispatchQueue.main.async {
                    let measuresList = self.sendAllMeasuresToWatch()
                    replyHandler(["userMeasures": measuresList])
                }
                return
            }
        }
    }
    
    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
    }
    
    func sendMeasureToWatch(measure: String) {
        let currentTime = CFAbsoluteTimeGetCurrent()
        
        if lastMessage + 0.25 > currentTime {
            return
        }
        
        if (WCSession.default.isReachable) {
            let message = ["Message": measure]
            WCSession.default.sendMessage(message, replyHandler: nil)
        }
        
        lastMessage = CFAbsoluteTimeGetCurrent()
    }
    
    func sendFinishPolygonMeasureToWatch() {
        
        if (WCSession.default.isReachable) {
            
            if let text = rulerScreen.messageLabel.text {
                let message = ["Message": text]
                WCSession.default.sendMessage(message, replyHandler: nil)
            }
        }
    }
    
    func sendAllMeasuresToWatch() ->[String] {
        
        var measuresList = [String]()
        
        if (WCSession.default.isReachable) {
            let userObjects = GRDatabaseManager.sharedDatabaseManager.grRealm.objects(UserObjectRm.self).sorted(byKeyPath: "createdAt", ascending: false)
            
            for measure in userObjects {
                let name = measure.name?.characters.prefix(6)
                let objectUnit = DistanceUnit(rawValue: measure.sizeUnit!)
                let measureDescription = name! + " " + String(format: "%.2f", measure.size) + " " + (objectUnit?.unit)!
                measuresList.append(measureDescription)
            }
        }
        
        return measuresList
    }
}
