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
        
    }
    
    @IBAction func makePoint() {
        
    }
    
    @IBAction func undoPressed() {
        
    }
}

extension InterfaceController: WCSessionDelegate {
    
    func session(_ session: WCSession, didReceiveMessage message: [String : Any]) {
        
        if let measure = message["Message"] as? String {
            measurePointsLabel.setText(measure)
        }
    }
    
    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
//        session.sendMessage(["reference": "test"], replyHandler: { (response) -> Void in
//            if let boardingPassData = response["testData"] as? Int {
//                
//                DispatchQueue.main.async {
//                    self.measure = String(boardingPassData)
//                    //self.showBoardingPass()
//                }
//            }
//        }, errorHandler: { (error) -> Void in
//            print(error)
//        })
    }
}
