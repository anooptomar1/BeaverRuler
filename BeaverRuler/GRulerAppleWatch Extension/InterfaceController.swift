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
        
        session = WCSession.default
//        session!.sendMessage(["reference": flight.reference], replyHandler: { (response) -> Void in
//            if let boardingPassData = response["boardingPassData"] as? NSData, boardingPass = UIImage(data: boardingPassData) {
//                flight.boardingPass = boardingPass
//                dispatch_async(dispatch_get_main_queue(), { () -> Void in
//                    self.showBoardingPass()
//                })
//            }
//        }, errorHandler: { (error) -> Void in
//            print(error)
//        })
    }
    
    @IBAction func makeScreenshot() {
        
    }
    
    @IBAction func makePoint() {
        
    }
    
    @IBAction func undoPressed() {
        
    }
}

extension InterfaceController: WCSessionDelegate {
    func session(session: WCSession, didReceiveMessage message: [String : AnyObject], replyHandler: @escaping ([String : AnyObject]) -> Void) {

    }
    
    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        
        
        
    }
}
