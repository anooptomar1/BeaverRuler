//
//  MeasuresListInterfaceController.swift
//  GRulerAppleWatch Extension
//
//  Created by user on 10/29/17.
//  Copyright © 2017 Sasha. All rights reserved.
//

import WatchKit
import Foundation
import WatchConnectivity

class UserMeasureModel {
    var measureName = ""
}

class MeasuresListInterfaceController: WKInterfaceController {
    @IBOutlet var tableView: WKInterfaceTable!
    
    var measures = [UserMeasureModel]()
    
    var session: WCSession? {
        didSet {
            if let session = session {
                session.delegate = self
                session.activate()
            }
        }
    }
    
    static var userMeasuresKey = "userMeasuresKey"
    
    override func didAppear() {
        super.didAppear()
        
        if WCSession.isSupported() {
            session = WCSession.default
            getDataFromPhone()
        } else {
            loadMeasuresFromDisc()
        }
        
        setUpTableView()
    }
    
    override func awake(withContext context: Any?) {
        super.awake(withContext: context)
    }
    
    func setUpTableView() {
        
        tableView.setNumberOfRows(measures.count, withRowType: "RecordRow")
        
        for index in 0..<tableView.numberOfRows {
            guard let controller = tableView.rowController(at: index) as? UserMeasureRowController else { continue }
            let playerRecordModel = measures[index]
            controller.userMeasure.setText(playerRecordModel.measureName)
        }
    }
    
    func loadMeasuresFromDisc() {
        
       if let data = UserDefaults.standard.object( forKey: MeasuresListInterfaceController.userMeasuresKey) as? [String] {
        
        for userMeasure in data {
            let newModel = UserMeasureModel()
            newModel.measureName = userMeasure
            self.measures.append(newModel)
        }
        
        }
    }
    
    func getDataFromPhone() {
        WCSession.default.sendMessage(["Message": "userMeasures"], replyHandler: { (response) -> Void in
            if let boardingPassData = response["userMeasures"] as? [String] {
                
                for userMeasure in boardingPassData {
                    let newModel = UserMeasureModel()
                    newModel.measureName = userMeasure
                    self.measures.append(newModel)
                }
                
                UserDefaults.standard.set(boardingPassData,
                                          forKey: MeasuresListInterfaceController.userMeasuresKey)
                
                DispatchQueue.main.async {
                    self.setUpTableView()
                }
            }
        }, errorHandler: { (error) -> Void in
            self.loadMeasuresFromDisc()
        })
        
    }
    
    override func willActivate() {
        super.willActivate()
    }
    
    override func didDeactivate() {
        super.didDeactivate()
    }
}

extension MeasuresListInterfaceController: WCSessionDelegate {
    
    func session(_ session: WCSession, didReceiveMessage message: [String : Any]) {
        
    }
    
    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        
    }
}
