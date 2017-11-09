//
//  InterfaceController.swift
//  GRulerAppleWatch Extension
//
//  Created by user on 10/28/17.
//  Copyright © 2017 Sasha. All rights reserved.
//

import WatchKit
import Foundation
import WatchConnectivity


class InterfaceController: WKInterfaceController {
    @IBOutlet var measurePointsLabel: WKInterfaceLabel!
    
    var lastMessage: CFAbsoluteTime = 0
    
    var measure: String? {
        didSet {
            if let measure = measure {
                measurePointsLabel.setText(measure)
            }
        }
    }
    
    var session: WCSession? {
        didSet {
            if let session = session {
                session.delegate = self
                session.activate()
            }
        }
    }
    
    override func awake(withContext context: Any?) {
        super.awake(withContext: context)
    }
    
    override func willActivate() {
        super.willActivate()
    }
    
    override func didDeactivate() {
        super.didDeactivate()
    }
    
    override func didAppear() {
        super.didAppear()
        
        if WCSession.isSupported() {
            session = WCSession.default
        }
    }
    
    @IBAction func makeScreenshot() {
        if (WCSession.default.isReachable) {
            let message = ["Message": "makeScreenshot"]
            WCSession.default.sendMessage(message, replyHandler: nil)
        }
    }
    
    @IBAction func makePoint() {
        if (WCSession.default.isReachable) {
            let message = ["Message": "makePoint"]
            WCSession.default.sendMessage(message, replyHandler: nil)
        }
    }
    
    @IBAction func doneButtonPressed() {
        if (WCSession.default.isReachable) {
            let message = ["Message": "donePressed"]
            WCSession.default.sendMessage(message, replyHandler: nil)
        }
    }
}

extension InterfaceController: WCSessionDelegate {
    
    func session(_ session: WCSession, didReceiveMessage message: [String : Any]) {
        
        if let measure = message["Message"] as? String {
            measurePointsLabel.setText(measure)
            
            let myDelegate = WKExtension.shared().delegate as! ExtensionDelegate
            myDelegate.currentMeasure = measure
            
            let currentTime = CFAbsoluteTimeGetCurrent()

            if lastMessage + 1 > currentTime {
                return
            }
            
            let complicationServer = CLKComplicationServer.sharedInstance()

            if let activeComplications = complicationServer.activeComplications {
                for complication in activeComplications {
                    complicationServer.reloadTimeline(for: complication)
                }
            }
            
            lastMessage = CFAbsoluteTimeGetCurrent()
        }
    }
    
    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
    }
}
