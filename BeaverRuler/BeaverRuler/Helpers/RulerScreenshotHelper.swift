//
//  RulerScreenshotHelper.swift
//  BeaverRuler
//
//  Created by user on 10/1/17.
//  Copyright © 2017 Sasha. All rights reserved.
//

import Foundation
import UIKit
import Crashlytics
import Photos
import Photos
import Vision

class RulerScreenshotHelper {
    
    var rulerScreen: ViewController!
    
    func makeScreenshot() {
        
        AppAnalyticsHelper.sendAppAnalyticEvent(withName: "Take_screenshot_pressed")
        rulerScreen.tutorialHelper.setUpTutorialStep6()
        
        if checkUserLimit() == true {
            return
        }
        
        let takeScreenshotBlock = {
            
            let image = self.rulerScreen.sceneView.snapshot()
            
            let date = Date()
            let uuid = String(Int(date.timeIntervalSince1970))
            
            let userObjectRm = UserObjectRm()
            userObjectRm.createdAt = date
            userObjectRm.id = uuid
            userObjectRm.sizeUnit = self.rulerScreen.unit.rawValue
            
            DispatchQueue.main.async {
                userObjectRm.name = self.getObjectName(id: uuid)
            }
            
            userObjectRm.size = self.getObjectSize()
            
            if let data = UIImagePNGRepresentation(image) {
                let filename = self.getDocumentsDirectory().appendingPathComponent(uuid + ".png")
                try? data.write(to: filename)
                userObjectRm.image = uuid + ".png"
            }
            
            DispatchQueue.main.async {
                try! GRDatabaseManager.sharedDatabaseManager.grRealm.write({
                    GRDatabaseManager.sharedDatabaseManager.grRealm.add(userObjectRm, update:true)
                })
                
                let userObjects = GRDatabaseManager.sharedDatabaseManager.grRealm.objects(UserObjectRm.self)
                AppAnalyticsHelper.sendAppAnalyticEvent(withName: "User_create_object_\(userObjects.count)")
            }
            
            UIImageWriteToSavedPhotosAlbum(image, nil, nil, nil)
            DispatchQueue.main.async {
                // Briefly flash the screen.
                let flashOverlay = UIView(frame: self.rulerScreen.sceneView.frame)
                flashOverlay.backgroundColor = UIColor.white
                self.rulerScreen.sceneView.addSubview(flashOverlay)
                UIView.animate(withDuration: 0.25, animations: {
                    flashOverlay.alpha = 0.0
                }, completion: { _ in
                    flashOverlay.removeFromSuperview()
                })
            }
        }
        
        switch PHPhotoLibrary.authorizationStatus() {
        case .authorized:
            takeScreenshotBlock()
        case .restricted, .denied:
            let title = NSLocalizedString("photosAccessDeniedTitle", comment: "")
            let message = NSLocalizedString("photosAccessDeniedMessage", comment: "")
            showAlert(title: title, message: message)
        case .notDetermined:
            PHPhotoLibrary.requestAuthorization({ (authorizationStatus) in
                if authorizationStatus == .authorized {
                    takeScreenshotBlock()
                }
            })
        }
        
    }
    
    func getObjectSize() -> Float {
        var polygonLength: Float = 0.0
        
        if rulerScreen.currentRulerType == RulerType.UsualRuler {
            for line in self.rulerScreen.lines {
                polygonLength = polygonLength + line.lineLength()
            }
        }
        
        if rulerScreen.currentRulerType == RulerType.СurveRuler {
            
            if let lastCurveLine = rulerScreen.curveLines.last {
                polygonLength = lastCurveLine.curveLength
            }
        }
        
        return polygonLength
    }
    
    func getObjectName(id: String) -> String {
        
        var objectName = "Object" + id
        
        if let currentFrame = rulerScreen.sceneView.session.currentFrame {
            do {
                let model = try VNCoreMLModel(for: SqueezeNet().model)
                let request = VNCoreMLRequest(model: model, completionHandler: { (request, error) in
                    // Jump onto the main thread
                    
                    guard let results = request.results as? [VNClassificationObservation], let result = results.first else {
                        print ("No results?")
                        return
                    }
                    
                    objectName = result.identifier
                })
                
                let handler = VNImageRequestHandler(cvPixelBuffer: currentFrame.capturedImage, options: [:])
                try handler.perform([request])
            } catch {}
        }
        
        return objectName
    }
    
    func checkUserLimit() -> Bool {
        
        let userObjects = GRDatabaseManager.sharedDatabaseManager.grRealm.objects(UserObjectRm.self)
        
        if userObjects.count >= rulerScreen.maxObjectsInUserGallery && rulerScreen.removeObjectsLimit == false {
            AppAnalyticsHelper.sendAppAnalyticEvent(withName: "User_reach_objects_limit")
            let objectsLimitTitle = NSLocalizedString("objectsLimit", comment: "")
            let alertController = UIAlertController(title: "\(objectsLimitTitle) \(rulerScreen.maxObjectsInUserGallery)", message: NSLocalizedString("doYouWhantToRemoveLimitMessage", comment: ""), preferredStyle: UIAlertControllerStyle.alert)
            
            alertController.addAction(UIAlertAction(title: NSLocalizedString("removeAdsPlusLimitButtonTitle", comment: ""), style: UIAlertActionStyle.default, handler: { UIAlertAction in
                for (_, product) in self.rulerScreen.products.enumerated() {
                    if product.productIdentifier == SettingsController.removeAdsPlusLimitProductId {
                        AppAnalyticsHelper.sendAppAnalyticEvent(withName: "Remove_ad_objects_limit_Ruler_Screen_pressed")
                        RageProducts.store.buyProduct(product)
                        break
                    }
                }
            }))
            
            alertController.addAction(UIAlertAction(title: NSLocalizedString("removeLimitButtonTitle", comment: ""), style: UIAlertActionStyle.default, handler: { UIAlertAction in
                for (_, product) in self.rulerScreen.products.enumerated() {
                    if product.productIdentifier == SettingsController.removeUserGalleryProductId {
                        AppAnalyticsHelper.sendAppAnalyticEvent(withName: "Buy_objects_limit_Ruler_Screen_pressed")
                        RageProducts.store.buyProduct(product)
                        break
                    }
                }
            }))
            
            alertController.addAction(UIAlertAction(title: NSLocalizedString("makeJustScreenshot", comment: ""), style: UIAlertActionStyle.default, handler: { UIAlertAction in
                self.takeJustScreenshot()
                AppAnalyticsHelper.sendAppAnalyticEvent(withName: "Make_just_screenshot_pressed")
            }))
            
            alertController.addAction(UIAlertAction(title: NSLocalizedString("noKey", comment: ""), style: UIAlertActionStyle.default, handler: nil))
            
            rulerScreen.present(alertController, animated: true, completion: nil)
            
            return true
        } else {
            return false
        }
    }
    
    func takeJustScreenshot() {
        
        let takeScreenshotBlock = {
            
            let image = self.rulerScreen.sceneView.snapshot()
            
            UIImageWriteToSavedPhotosAlbum(image, nil, nil, nil)
            DispatchQueue.main.async {
                // Briefly flash the screen.
                let flashOverlay = UIView(frame: self.rulerScreen.sceneView.frame)
                flashOverlay.backgroundColor = UIColor.white
                self.rulerScreen.sceneView.addSubview(flashOverlay)
                UIView.animate(withDuration: 0.25, animations: {
                    flashOverlay.alpha = 0.0
                }, completion: { _ in
                    flashOverlay.removeFromSuperview()
                })
            }
        }
        
        switch PHPhotoLibrary.authorizationStatus() {
        case .authorized:
            takeScreenshotBlock()
        case .restricted, .denied:
            let title = NSLocalizedString("photosAccessDeniedTitle", comment: "")
            let message = NSLocalizedString("photosAccessDeniedMessage", comment: "")
            showAlert(title: title, message: message)
        case .notDetermined:
            PHPhotoLibrary.requestAuthorization({ (authorizationStatus) in
                if authorizationStatus == .authorized {
                    takeScreenshotBlock()
                }
            })
        }
        
    }
    
    func getDocumentsDirectory() -> URL {
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        let documentsDirectory = paths[0]
        return documentsDirectory
    }
    
    func showAlert(title: String, message: String, actions: [UIAlertAction]? = nil) {
        let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
        if let actions = actions {
            for action in actions {
                alertController.addAction(action)
            }
        } else {
            alertController.addAction(UIAlertAction(title: NSLocalizedString("okKey", comment: ""), style: .default, handler: nil))
        }
        rulerScreen.present(alertController, animated: true, completion: nil)
    }
    
}
