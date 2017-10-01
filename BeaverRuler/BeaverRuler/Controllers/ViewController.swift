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
import Appodeal

class ViewController: UIViewController {
    
    let finishTutorialKey = "finishTutorialKey"
    let maxObjectsInUserGallery = 5
    
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
    lazy var lines: [RulerLine] = []
    fileprivate var currentLine: RulerLine?
    lazy var unit: DistanceUnit = .centimeter
    
    fileprivate var alertController: UIAlertController?
    
    var products = [SKProduct]()
    var removeObjectsLimit = false
    
    var tutorialHelper = TutorialHelper()
    
    var apdAdQueue : APDNativeAdQueue = APDNativeAdQueue()
    var capacity : Int = 9
    var type : APDNativeAdType = .auto
    
    var rulerScreenNavigationHelper = RulerNavigationHelper()
    var rulerScreenshotHelper = RulerScreenshotHelper()
    
    override func viewDidLoad() {
        super.viewDidLoad()

        rulerScreenNavigationHelper.rulerScreen = self
        rulerScreenshotHelper.rulerScreen = self
        
        let defaults = UserDefaults.standard
        if let measureString = defaults.string(forKey: Setting.measureUnits.rawValue) {
            self.unit = DistanceUnit(rawValue: measureString)!
        } else {
            self.unit = .centimeter
            defaults.set(DistanceUnit.centimeter.rawValue, forKey: Setting.measureUnits.rawValue)
        }
        
        tutorialHelper.tutorialStep1Image = tutorialStep1Image
        tutorialHelper.tutorialStep2Image = tutorialStep2Image
        tutorialHelper.tutorialStep3Image = tutorialStep3Image
        tutorialHelper.tutorialStep4Image = tutorialStep4Image
        tutorialHelper.setUpTutorialStep1()
        
        NotificationCenter.default.addObserver(self, selector: #selector(ViewController.handlePurchaseNotification(_:)),
                                               name: NSNotification.Name(rawValue: IAPHelper.IAPHelperPurchaseNotification),
                                               object: nil)
        
        NotificationCenter.default.addObserver(self, selector: #selector(ViewController.handleStartARSessionNotification(_:)),
                                               name: Notification.Name(rawValue:AppFeedbackHelper.appFeedbackHelperNotificationKey),
                                               object: nil)

        setupScene()
        loadInAppsPurchases()
        AppAnalyticsHelper.sendAppAnalyticEvent(withName: "Ruler_Screen")
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
            
            tutorialHelper.setUpTutorialStep3()
            resetValues()
            isMeasuring = true
            targetImageView.image = UIImage(named: "targetGreen")
            AppAnalyticsHelper.sendAppAnalyticEvent(withName: "User_make_start_point")

        } else {
            if let line = currentLine {
                lines.append(line)
                currentLine = RulerLine(sceneView: sceneView, startVector: endValue, unit: unit)
                AppAnalyticsHelper.sendAppAnalyticEvent(withName: "User_make_next_point")
            }
        }
    }

    // MARK: - Users Interactions

    @IBAction func finishPolygonPressed(_ sender: Any) {
        AppAnalyticsHelper.sendAppAnalyticEvent(withName: "Finish_polygon_pressed")
        if currentLine != nil {
            isMeasuring = false
            targetImageView.image = UIImage(named: "targetWhite")
            currentLine?.removeFromParentNode()
            currentLine = nil
            setUpMessageLabel()
        }
    }

    @IBAction func undoPressed(_ sender: Any) {
        AppAnalyticsHelper.sendAppAnalyticEvent(withName: "Undo_pressed")
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
        rulerScreenNavigationHelper.showSettingsScreen()
    }

    private func updateSettings() {
        let defaults = UserDefaults.standard
        self.unit = DistanceUnit(rawValue: defaults.string(forKey: Setting.measureUnits.rawValue)!)!
    }

    @IBAction func galleryButtonPressed(_ sender: Any) {
        rulerScreenNavigationHelper.showGalleryScreen()
    }

    @IBAction func resetButtonTapped(_ sender: Any) {
        AppAnalyticsHelper.sendAppAnalyticEvent(withName: "Clean_pressed")
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
        rulerScreenshotHelper.makeScreenshot()
    }
    
    // MARK: - In app purchases
    
    func loadInAppsPurchases() {
        
        if RageProducts.store.isProductPurchased(SettingsController.removeUserGalleryProductId) || RageProducts.store.isProductPurchased(SettingsController.removeAdsPlusLimitProductId) {
            removeObjectsLimit = true
        }
        
        if (RageProducts.store.isProductPurchased(SettingsController.removeAdProductId)) || (RageProducts.store.isProductPurchased(SettingsController.removeAdsPlusLimitProductId)) {
            
        } else {
            apdAdQueue.setMaxAdSize(capacity)
            apdAdQueue.loadAd(of: type)
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
            AppAnalyticsHelper.sendAppAnalyticEvent(withName: "User_buy_objects_Ruler_screen_limit")
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
    
    @objc func handleStartARSessionNotification(_ notification: Notification) {
        session.run(sessionConfiguration)
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
            
            AppAnalyticsHelper.sendAppAnalyticEvent(withName: "User_cancel_camera_permissions")
            
            let alert = UIAlertController(title: NSLocalizedString("GRulerWouldLikeToAccessTheCamera", comment: ""), message: NSLocalizedString("pleaseGrantPermissionToUseTheCamera", comment: ""), preferredStyle: .alert )
            alert.addAction(UIAlertAction(title: NSLocalizedString("openSettings", comment: ""), style: .cancel) { alert in

                UIApplication.shared.open(URL(string: UIApplicationOpenSettingsURLString)!, options: [:], completionHandler: { (success) in
                })

            })
            present(alert, animated: true, completion: nil)

        }
        
        messageLabel.text = NSLocalizedString("errorOccurred", comment: "")
    }

    func sessionWasInterrupted(_ session: ARSession) {
        messageLabel.text = NSLocalizedString("interrupted", comment: "")
    }

    func sessionInterruptionEnded(_ session: ARSession) {
        messageLabel.text = NSLocalizedString("interruptionEnded", comment: "")
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
        messageLabel.text = NSLocalizedString("detectingTheWorld", comment: "")
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
        
        tutorialHelper.setUpTutorialStep2()
        
        targetImageView.isHidden = false
        if lines.isEmpty {
            messageLabel.text = NSLocalizedString("touchYourPhoneScreen", comment: "")
        }
        loadingView.stopAnimating()
        loadingView.isHidden = true
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
            messageLabel.text = currentLine?.distance(to: endValue) ?? NSLocalizedString("сalculating", comment: "")
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
