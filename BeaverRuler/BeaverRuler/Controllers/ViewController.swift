//
//  ViewController.swift
//  BeaverRuler
//
//  Created by Sasha on 8/16/17.
//  Copyright © 2017 Sasha. All rights reserved.
//

import UIKit
import SceneKit
import ARKit
import Photos
import StoreKit
import Crashlytics
import Vision

class ViewController: UIViewController {
    
    let finishTutorialKey = "finishTutorialKey"
    let maxObjectsInUserGallery = 30
    
    @IBOutlet var sceneView: ARSCNView!
    @IBOutlet weak var targetImageView: UIImageView!
    @IBOutlet weak var loadingView: UIActivityIndicatorView!
    @IBOutlet weak var messageLabel: UILabel!
    @IBOutlet weak var settingsButton: UIButton!
    @IBOutlet weak var resetButton: UIButton!
    @IBOutlet weak var galleryButton: UIButton!
    
    
    @IBOutlet weak var tutorialStep1Image: UIImageView!
    @IBOutlet weak var tutorialStep2Image: UIImageView!
    @IBOutlet weak var tutorialStep3Image: UIImageView!
    @IBOutlet weak var tutorialStep4Image: UIImageView!
    
    fileprivate lazy var session = ARSession()
    fileprivate lazy var sessionConfiguration = ARWorldTrackingConfiguration()
    fileprivate lazy var isMeasuring = false;
    fileprivate lazy var vectorZero = SCNVector3()
    fileprivate lazy var startValue = SCNVector3()
    fileprivate lazy var endValue = SCNVector3()
    fileprivate lazy var lines: [RulerLine] = []
    fileprivate var currentLine: RulerLine?
    fileprivate lazy var unit: DistanceUnit = .centimeter
    fileprivate var alertController: UIAlertController?
    
    fileprivate var products = [SKProduct]()
    fileprivate var removeObjectsLimit = false
    
    fileprivate var finishTutorial = false
    fileprivate var tutorialStep = 0
    
    override func viewDidLoad() {
        super.viewDidLoad()

        let defaults = UserDefaults.standard

        if let measureString = defaults.string(forKey: Setting.measureUnits.rawValue) {
            self.unit = DistanceUnit(rawValue: measureString)!
        } else {
            self.unit = .centimeter
            defaults.set(DistanceUnit.centimeter.rawValue, forKey: Setting.measureUnits.rawValue)
        }
        
        finishTutorial = defaults.bool(forKey: finishTutorialKey)
        
        if finishTutorial {
            tutorialStep1Image.isHidden = true
            tutorialStep2Image.isHidden = true
            tutorialStep3Image.isHidden = true
            tutorialStep4Image.isHidden = true
        } else {
            tutorialStep1Image.isHidden = false
            tutorialStep2Image.isHidden = true
            tutorialStep3Image.isHidden = true
            tutorialStep4Image.isHidden = true
            tutorialStep = 1
            Answers.logCustomEvent(withName: "User start tutorial")
        }
        
        NotificationCenter.default.addObserver(self, selector: #selector(ViewController.handlePurchaseNotification(_:)),
                                               name: NSNotification.Name(rawValue: IAPHelper.IAPHelperPurchaseNotification),
                                               object: nil)

        setupScene()
        loadInAppsPurchases()
        Answers.logCustomEvent(withName: "Ruler Screen")
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        UIApplication.shared.isIdleTimerDisabled = true
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        session.pause()
    }

    override var prefersStatusBarHidden: Bool {
        return true
    }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        if currentLine == nil {
            
            if finishTutorial == false && tutorialStep == 2 {
                tutorialStep2Image.isHidden = true
                tutorialStep3Image.isHidden = false
                tutorialStep = 3
                Answers.logCustomEvent(withName: "User finish tutorial step 2")
            }
            
            resetValues()
            isMeasuring = true
            targetImageView.image = UIImage(named: "targetGreen")
            Answers.logCustomEvent(withName: "User make start point")

        } else {
            if let line = currentLine {
                lines.append(line)
                currentLine = RulerLine(sceneView: sceneView, startVector: endValue, unit: unit)
                Answers.logCustomEvent(withName: "User make next point")
            }
        }
    }

    // MARK: - Users Interactions

    @IBAction func finishPolygonPressed(_ sender: Any) {
        Answers.logCustomEvent(withName: "Finish polygon pressed")
        if currentLine != nil {
            isMeasuring = false
            targetImageView.image = UIImage(named: "targetWhite")
            currentLine?.removeFromParentNode()
            currentLine = nil
            setUpMessageLabel()
        }
    }

    @IBAction func undoPressed(_ sender: Any) {
        Answers.logCustomEvent(withName: "Undo pressed")
        if let line = currentLine {
            line.removeFromParentNode()
            currentLine = nil

        } else {
            if lines.count > 0 {

                let previouseLine = lines.last
                previouseLine?.removeFromParentNode()
                lines.removeLast()

                currentLine = RulerLine(sceneView: sceneView, startVector: (previouseLine?.startVector)!, unit: unit)
                currentLine?.update(to: endValue)
                isMeasuring = true
            }
        }
    }

    @IBAction func showSettings(_ sender: Any) {
        Answers.logCustomEvent(withName: "Show settings pressed")
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        guard let settingsViewController = storyboard.instantiateViewController(withIdentifier: "SettingsController") as? SettingsController else {
            return
        }

        let barButtonItem = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(dismissSettings))
        settingsViewController.navigationItem.rightBarButtonItem = barButtonItem
        settingsViewController.title = "Options"
        settingsViewController.products = products

        let navigationController = UINavigationController(rootViewController: settingsViewController)
        navigationController.modalPresentationStyle = .popover
        navigationController.popoverPresentationController?.delegate = self
        navigationController.preferredContentSize = CGSize(width: sceneView.bounds.size.width - 20, height: sceneView.bounds.size.height - 50)
        self.present(navigationController, animated: true, completion: nil)

        navigationController.popoverPresentationController?.sourceView = settingsButton
        navigationController.popoverPresentationController?.sourceRect = settingsButton.bounds

    }

    @objc
    func dismissSettings() {
        self.dismiss(animated: true, completion: nil)
        updateSettings()
    }

    private func updateSettings() {
        let defaults = UserDefaults.standard
        self.unit = DistanceUnit(rawValue: defaults.string(forKey: Setting.measureUnits.rawValue)!)!
    }

    @IBAction func galleryButtonPressed(_ sender: Any) {
        Answers.logCustomEvent(withName: "Show user gallery pressed")
        if finishTutorial == false && tutorialStep == 4 {
            tutorialStep4Image.isHidden = true
            finishTutorial = true
            
            let defaults = UserDefaults.standard
            defaults.set(finishTutorial, forKey: finishTutorialKey)
            Answers.logCustomEvent(withName: "User finish tutorial")
        }
        
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        guard let settingsViewController = storyboard.instantiateViewController(withIdentifier: "ObjectsFoldersViewController") as? ObjectsFoldersViewController else {
            return
        }

        let barButtonItem = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(dismissSettings))
        settingsViewController.navigationItem.rightBarButtonItem = barButtonItem
        settingsViewController.title = "Gallery"

        let navigationController = UINavigationController(rootViewController: settingsViewController)
        navigationController.modalPresentationStyle = .popover
        navigationController.popoverPresentationController?.delegate = self
        navigationController.preferredContentSize = CGSize(width: sceneView.bounds.size.width - 20, height: sceneView.bounds.size.height - 50)
        self.present(navigationController, animated: true, completion: nil)

        navigationController.popoverPresentationController?.sourceView = galleryButton
        navigationController.popoverPresentationController?.sourceRect = galleryButton.bounds
    }

    @IBAction func resetButtonTapped(_ sender: Any) {
        Answers.logCustomEvent(withName: "Clean pressed")
        for line in lines {
            line.removeFromParentNode()
        }
        lines.removeAll()

        if let line = currentLine {
            line.removeFromParentNode()
            currentLine = nil
        }
    }

    @IBAction func takeScreenshot() {
        Answers.logCustomEvent(withName: "Take screenshot pressed")
        if finishTutorial == false && tutorialStep == 3 {
            tutorialStep3Image.isHidden = true
            tutorialStep4Image.isHidden = false
            tutorialStep = 4
            Answers.logCustomEvent(withName: "User finish tutorial step 3")
        }
        
        if checkUserLimit() == true {
            return
        }
        
        let takeScreenshotBlock = {
            
            let image = self.sceneView.snapshot()
            
            let date = Date()
            let uuid = String(Int(date.timeIntervalSince1970))
            
            let userObjectRm = UserObjectRm()
            userObjectRm.createdAt = date
            userObjectRm.id = uuid
            userObjectRm.sizeUnit = self.unit.rawValue
            
            DispatchQueue.main.async {
                userObjectRm.name = self.getObjectName(id: uuid)
            }
            
            var polygonLength: Float = 0.0
            for line in self.lines {
                polygonLength = polygonLength + line.lineLength()
            }
            userObjectRm.size = polygonLength
            
            if let data = UIImagePNGRepresentation(image) {
                let filename = self.getDocumentsDirectory().appendingPathComponent(uuid + ".png")
                try? data.write(to: filename)
                userObjectRm.image = uuid + ".png"
            }

            DispatchQueue.main.async {
                try! GRDatabaseManager.sharedDatabaseManager.grRealm.write({
                    GRDatabaseManager.sharedDatabaseManager.grRealm.add(userObjectRm, update:true)
                })
            }

            UIImageWriteToSavedPhotosAlbum(image, nil, nil, nil)
            DispatchQueue.main.async {
                // Briefly flash the screen.
                let flashOverlay = UIView(frame: self.sceneView.frame)
                flashOverlay.backgroundColor = UIColor.white
                self.sceneView.addSubview(flashOverlay)
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
            let title = "Photos access denied"
            let message = "Please enable Photos access for this application in Settings > Privacy to allow saving screenshots."
            showAlert(title: title, message: message)
        case .notDetermined:
            PHPhotoLibrary.requestAuthorization({ (authorizationStatus) in
                if authorizationStatus == .authorized {
                    takeScreenshotBlock()
                }
            })
        }
    }
    
    func getObjectName(id: String) -> String {
        
        var objectName = "Object" + id
        
        if let currentFrame = sceneView.session.currentFrame {
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
        
        if userObjects.count >= maxObjectsInUserGallery && removeObjectsLimit == false {
            Answers.logCustomEvent(withName: "User reach objects limit")
            let alertController = UIAlertController(title: "Objects limit: \(maxObjectsInUserGallery)", message:
                "Do you whant to remove limit?", preferredStyle: UIAlertControllerStyle.alert)
            alertController.addAction(UIAlertAction(title: "NO", style: UIAlertActionStyle.default, handler: nil))
            alertController.addAction(UIAlertAction(title: "BUY", style: UIAlertActionStyle.default, handler: { UIAlertAction in
                for (_, product) in self.products.enumerated() {
                    if product.productIdentifier == SettingsController.removeUserGalleryProductId {
                        Answers.logCustomEvent(withName: "Buy objects limit(Ruler Screen) pressed")
                        RageProducts.store.buyProduct(product)
                        break
                    }
                }
            }))
            self.present(alertController, animated: true, completion: nil)
            
            return true
        } else {
            return false
        }
    }
    
    func getDocumentsDirectory() -> URL {
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        let documentsDirectory = paths[0]
        return documentsDirectory
    }

    func showAlert(title: String, message: String, actions: [UIAlertAction]? = nil) {
        alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
        if let actions = actions {
            for action in actions {
                alertController!.addAction(action)
            }
        } else {
            alertController!.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
        }
        self.present(alertController!, animated: true, completion: nil)
    }
    
    // MARK: - In app purchases
    
    func loadInAppsPurchases() {
        
        if RageProducts.store.isProductPurchased(SettingsController.removeUserGalleryProductId) || RageProducts.store.isProductPurchased(SettingsController.removeAdsPlusLimitProductId) {
            removeObjectsLimit = true
        }
        
        products = []
        RageProducts.store.requestProducts{success, products in
            if success {
                self.products = products!
            }
        }
    }
    
    @objc func handlePurchaseNotification(_ notification: Notification) {
        guard let productID = notification.object as? String else { return }
        
        if productID == SettingsController.removeUserGalleryProductId  {
            Answers.logCustomEvent(withName: "User buy objects(Ruler screen) limit")
            Answers.logPurchase(withPrice: 1.99,
                                         currency: "USD",
                                         success: true,
                                         itemName: "Remove objects limit",
                                         itemType: "In app",
                                         itemId: productID,
                                         customAttributes: [:])
            removeObjectsLimit = true
        }
        
    }

}

// MARK: - ARSCNViewDelegate

extension ViewController: ARSCNViewDelegate {
    func renderer(_ renderer: SCNSceneRenderer, updateAtTime time: TimeInterval) {
        DispatchQueue.main.async { [weak self] in
            self?.detectObjects()
        }
    }

    func session(_ session: ARSession, didFailWithError error: Error) {
        
        let errorCode = (error as NSError).code
        
        if errorCode == 103 {
            
            Answers.logCustomEvent(withName: "User cancel camera permissions")
            
            let alert = UIAlertController(title: "GRuler Would Like To Access the Camera", message: "Please grant permission to use the Camera.", preferredStyle: .alert )
            alert.addAction(UIAlertAction(title: "Open Settings", style: .cancel) { alert in

                UIApplication.shared.open(URL(string: UIApplicationOpenSettingsURLString)!, options: [:], completionHandler: { (success) in
                })

            })
            present(alert, animated: true, completion: nil)

        }
        
        messageLabel.text = "Error occurred"
    }

    func sessionWasInterrupted(_ session: ARSession) {
        messageLabel.text = "Interrupted"
    }

    func sessionInterruptionEnded(_ session: ARSession) {
        messageLabel.text = "Interruption ended"
    }
    
    func session(_ session: ARSession, cameraDidChangeTrackingState camera: ARCamera) {
//        switch camera.trackingState {
//        case .notAvailable:
//            trackingStateLabel.text = "Tracking not available"
//            trackingStateLabel.textColor = .red
//        case .normal:
//            trackingStateLabel.text = "Tracking normal"
//            trackingStateLabel.textColor = .green
//        case .limited(let reason):
//            switch reason {
//            case .excessiveMotion:
//                trackingStateLabel.text = "Tracking limited: excessive motion"
//            case .insufficientFeatures:
//                trackingStateLabel.text = "Tracking limited: insufficient features"
//            case .initializing:
//                trackingStateLabel.text = "Tracking limited: initializing"
//            }
//            trackingStateLabel.textColor = .yellow
//        }
    }
}

// MARK: - UIPopoverPresentationControllerDelegate

extension ViewController: UIPopoverPresentationControllerDelegate {
    func adaptivePresentationStyle(for controller: UIPresentationController) -> UIModalPresentationStyle {
        return .none
    }

    func popoverPresentationControllerDidDismissPopover(_ popoverPresentationController: UIPopoverPresentationController) {
        updateSettings()
    }
}

// MARK: - Privates

extension ViewController {
    fileprivate func setupScene() {
        targetImageView.isHidden = true
        sceneView.delegate = self
        sceneView.session = session
        loadingView.startAnimating()
        settingsButton.isHidden = true
        messageLabel.text = "Detecting the world…"
        session.run(sessionConfiguration, options: [.resetTracking, .removeExistingAnchors])
        resetValues()
    }

    fileprivate func resetValues() {
        isMeasuring = false
        startValue = SCNVector3()
        endValue =  SCNVector3()
    }

    fileprivate func detectObjects() {
        
        guard let worldPosition = sceneView.realWorldVector(screenPosition: view.center) else { return }
        
        if finishTutorial == false && tutorialStep == 1 {
            tutorialStep1Image.isHidden = true
            tutorialStep2Image.isHidden = false
            tutorialStep = 2
        }
        
        targetImageView.isHidden = false
        settingsButton.isHidden = false
        if lines.isEmpty {
            messageLabel.text = "Touch your phone screen…"
        }
        loadingView.stopAnimating()
        if isMeasuring {
            if startValue == vectorZero {
                startValue = worldPosition
                currentLine = RulerLine(sceneView: sceneView, startVector: startValue, unit: unit)
            }

            endValue = getEndValue(worldPosition: worldPosition)
            currentLine?.unit = unit
            currentLine?.update(to: endValue)
            setUpMessageLabel()
        }
    }
    
    func setUpMessageLabel() {
        if lines.count > 0 {
            var polygonLength: Float = 0.0
            for line in self.lines {
                polygonLength = polygonLength + line.lineLength()
            }
            if currentLine != nil {
                polygonLength += (currentLine?.lineLength())!
            }
                
            messageLabel.text = String(format: "%.2f %@", polygonLength, unit.unit)
        } else {
            messageLabel.text = currentLine?.distance(to: endValue) ?? "Calculating…"
        }
    }

    fileprivate func getEndValue(worldPosition: SCNVector3) -> SCNVector3{

        var position = worldPosition

        if currentLine != nil {

            if lines.count > 0 {
                let startLine = lines.first
                let startPoint = startLine?.startVector

                let distance = distanceBetweenPoints(firtsPoint: sceneView.projectPoint(worldPosition), secondPoint: sceneView.projectPoint(startPoint!))
                if distance < 9 {
                    position = startPoint!
                }

            }
        }

        return position
    }

    fileprivate func distanceBetweenPoints(firtsPoint:SCNVector3, secondPoint:SCNVector3) -> Float{
        let xd = firtsPoint.x - secondPoint.x
        let yd = firtsPoint.y - secondPoint.y
        let zd = firtsPoint.z - secondPoint.z
        let distance = Float(sqrt(xd * xd + yd * yd + zd * zd))

        if (distance < 0){
            return (distance * -1)
        } else {
            return (distance)
        }
    }
}
