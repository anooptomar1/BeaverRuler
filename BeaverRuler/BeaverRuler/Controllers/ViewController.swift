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
import AVFoundation
import WatchConnectivity

class ViewController: UIViewController {
    
    let finishTutorialKey = "finishTutorialKey"
    let maxObjectsInUserGallery = 3
    
    @IBOutlet var sceneView: ARSCNView!
    @IBOutlet weak var targetImageView: UIImageView!
    @IBOutlet weak var loadingView: UIActivityIndicatorView!
    @IBOutlet weak var messageLabel: UILabel!
    @IBOutlet weak var angleLabel: UILabel!
    @IBOutlet weak var settingsButton: UIButton!
    @IBOutlet weak var resetButton: UIButton!
    @IBOutlet weak var galleryButton: UIButton!
    
    @IBOutlet weak var tutorialStep1Image: UIImageView!
    @IBOutlet weak var tutorialStep2Image: UIImageView!
    @IBOutlet weak var tutorialStep4Image: UIImageView!
    @IBOutlet weak var tutorialStep5Image: UIImageView!
    @IBOutlet weak var tutorialStep6Image: UIImageView!
    @IBOutlet weak var draggingTutorialImage: UIImageView!
    
    fileprivate lazy var session = ARSession()
    fileprivate lazy var sessionConfiguration = ARWorldTrackingConfiguration()
    lazy var isMeasuring = false;
    lazy var vectorZero = SCNVector3()
    lazy var startValue = SCNVector3()
    lazy var endValue = SCNVector3()
    lazy var lines: [RulerLine] = []
    var currentLine: RulerLine?
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
    var rulerPurchasesHelper: RulerPurchasesHelper!
    var rulerMeasurementsHelper = RulerMeasurementsHelper()
    var rulerAppleWatchHelper = RulerAppleWatchHelper()
    var rulerARHelper = RulerARHelper()
    
    var showCurrentLine = true
    var startSelectedNode:SCNNode?
    var endSelectedNode:SCNNode?
    var startNodeLine: RulerLine?
    var endNodeLine: RulerLine?
    var userDraggingPoint = false
    
    var showUserInterstitial = false
    
    var appleWatchSession: WCSession? {
        didSet {
            if let session = appleWatchSession {
                session.delegate = rulerAppleWatchHelper
                session.activate()
            }
        }
    }
    
    var lastMessage: CFAbsoluteTime = 0
    
    override func viewDidLoad() {
        super.viewDidLoad()

        Appodeal.setInterstitialDelegate(self)
        
        rulerScreenNavigationHelper.rulerScreen = self
        rulerScreenshotHelper.rulerScreen = self
        rulerPurchasesHelper = RulerPurchasesHelper(rulerScreen: self)
        rulerMeasurementsHelper.rulerScreen = self
        rulerAppleWatchHelper.rulerScreen = self
        rulerARHelper.rulerScreen = self
        
        let defaults = UserDefaults.standard
        if let measureString = defaults.string(forKey: Setting.measureUnits.rawValue) {
            self.unit = DistanceUnit(rawValue: measureString)!
        } else {
            self.unit = .centimeter
            defaults.set(DistanceUnit.centimeter.rawValue, forKey: Setting.measureUnits.rawValue)
        }
        
        tutorialHelper.tutorialStep1Image = tutorialStep1Image
        tutorialHelper.tutorialStep2Image = tutorialStep2Image
        tutorialHelper.tutorialStep4Image = tutorialStep4Image
        tutorialHelper.tutorialStep5Image = tutorialStep5Image
        tutorialHelper.tutorialStep6Image = tutorialStep6Image
        tutorialHelper.draggingTutorialImage = draggingTutorialImage
        
        tutorialHelper.setUpTutorialStep1()
        
        NotificationCenter.default.addObserver(self, selector: #selector(ViewController.handleStartARSessionNotification(_:)),
                                               name: Notification.Name(rawValue:AppFeedbackHelper.appFeedbackHelperNotificationKey),
                                               object: nil)

        setupScene()
        AppAnalyticsHelper.sendAppAnalyticEvent(withName: "Ruler_Screen")
        
        
        let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(ViewController.tapGesture))
        self.view.addGestureRecognizer(tapGestureRecognizer)
        
        let longGesture = UILongPressGestureRecognizer(target: self, action: #selector(ViewController.longTap))
        self.view.addGestureRecognizer(longGesture)
        
        if WCSession.isSupported() {
            appleWatchSession = WCSession.default
        }
        
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
    
    @objc func tapGesture(sender: UITapGestureRecognizer)
    {
        nextPointTap()
    }
    
    @objc func longTap(_ sender: UIGestureRecognizer){
        
        if sender.state == .ended {
            
            AppAnalyticsHelper.sendAppAnalyticEvent(withName: "User_end_dragging_point")
            userDraggingPoint = false
            
            if isMeasuring == false {
                showCurrentLine = true
            }
            
        } else if sender.state == .began {
            AppAnalyticsHelper.sendAppAnalyticEvent(withName: "User_start_dragging_point")
            showCurrentLine = false
            userDraggingPoint = true
        }
    }
    
    func nextPointTap() {
        
        if showCurrentLine {
            if currentLine == nil {
                
                tutorialHelper.setUpTutorialStep3()
                
                resetValues()
                isMeasuring = true
                targetImageView.image = UIImage(named: "targetGreen")
                AppAnalyticsHelper.sendAppAnalyticEvent(withName: "User_make_start_point")
                
            } else {
                if let line = currentLine {
                    
                    if tutorialHelper.showSecondPointTutorial {
                        tutorialHelper.setUpTutorialStep4()
                        tutorialHelper.showSecondPointTutorial = false
                    }
                    
                    lines.append(line)
                    currentLine = RulerLine(sceneView: sceneView, startVector: endValue, unit: unit)
                    currentLine?.lastLineStartVector = lines.last?.startVector
                    AppAnalyticsHelper.sendAppAnalyticEvent(withName: "User_make_next_point")
                }
            }
        } else {
            showCurrentLine = true
            if (currentLine != nil) && lines.count > 0 {
                let lastLine = lines.last
                
                if let endVector = lastLine?.endVector {
                    currentLine?.updateStartPoint(to: endVector)
                }
            }
        }
    }
    
    func updateSelectedLines() {
        if (startSelectedNode != nil) || (endSelectedNode != nil) {
            if let worldPosition = sceneView.realWorldVector(screenPosition: view.center) {
                
                if (startNodeLine != nil) {
                    let startValue = rulerMeasurementsHelper.getEndValue(worldPosition: worldPosition)
                    startNodeLine?.updateStartPoint(to: startValue)
                    if ((startNodeLine?.lastLineStartVector) != nil) {
                        angleLabel.text = (startNodeLine?.getAngleBetween3Vectors())!
                    }
                }
                
                if (endNodeLine != nil) {
                    let endValue = rulerMeasurementsHelper.getEndValue(worldPosition: worldPosition)
                    endNodeLine?.update(to: endValue)
                }
                
                setUpMessageLabel()
            }
        }
    }
    
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        showCurrentLine = true
    }

    // MARK: - Users Interactions

    @IBAction func finishPolygonPressed(_ sender: Any) {
        AppAnalyticsHelper.sendAppAnalyticEvent(withName: "Finish_polygon_pressed")
        if currentLine != nil {
            tutorialHelper.setUpTutorialStep5()
            isMeasuring = false
            targetImageView.image = UIImage(named: "targetWhite")
            currentLine?.removeFromParentNode()
            currentLine = nil
            showCurrentLine = true
            angleLabel.text = ""
            setUpMessageLabel()
            rulerAppleWatchHelper.sendFinishPolygonMeasureToWatch()
        }
    }
    
    @IBAction func rateGamePressed(_ sender: Any) {
        AppAnalyticsHelper.sendAppAnalyticEvent(withName: "Rate_app_pressed_Ruler_screen")
        APAppRater.sharedInstance.rateTheApp()
    }
    
    @IBAction func turnLightPressed(_ sender: Any) {
        guard let device = AVCaptureDevice.default(for: AVMediaType.video)
            else {return}
        
        if device.hasTorch {
            do {
                try device.lockForConfiguration()
                
                if device.torchMode == .off {
                    device.torchMode = .on
                    AppAnalyticsHelper.sendAppAnalyticEvent(withName: "TurnOn_torch")
                } else {
                    device.torchMode = .off
                    AppAnalyticsHelper.sendAppAnalyticEvent(withName: "TurnOff_torch")
                }
                
                device.unlockForConfiguration()
            } catch {
                print("Torch could not be used")
            }
        } else {
            print("Torch is not available")
        }
    }
    
    @IBAction func buyButtonPressed(_ sender: Any) {
        AppAnalyticsHelper.sendAppAnalyticEvent(withName: "Purchases_popUp_pressed")
        rulerPurchasesHelper.showPurchasesPopUp()
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
                currentLine?.lastLineStartVector = lines.last?.startVector
                isMeasuring = true
            }
        }
    }

    @IBAction func showSettings(_ sender: Any) {
        
        var blockAd = false
        
        if RageProducts.store.isProductPurchased(SettingsController.removeAdProductId) || RageProducts.store.isProductPurchased(SettingsController.removeAdsPlusLimitProductId) {
            blockAd = true
        }
        
        if showUserInterstitial == false && Appodeal.isReadyForShow(with: AppodealShowStyle.interstitial) && blockAd == false {
            Appodeal.showAd(AppodealShowStyle.interstitial, rootViewController: self)
            showUserInterstitial = true
        } else {
            rulerScreenNavigationHelper.showSettingsScreen()
        }
    }

    private func updateSettings() {
        let defaults = UserDefaults.standard
        self.unit = DistanceUnit(rawValue: defaults.string(forKey: Setting.measureUnits.rawValue)!)!
    }

    @IBAction func galleryButtonPressed(_ sender: Any) {
        self.rulerScreenNavigationHelper.showGalleryScreen()
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
        self.rulerScreenshotHelper.makeScreenshot()
    }
    
    @objc func handleStartARSessionNotification(_ notification: Notification) {
        session.run(sessionConfiguration)
    }

}

// MARK: - ARSCNViewDelegate

extension ViewController: ARSCNViewDelegate {
    func renderer(_ renderer: SCNSceneRenderer, updateAtTime time: TimeInterval) {
        DispatchQueue.main.async { [weak self] in
            self?.rulerARHelper.detectObjects()
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

// MARK: - AppodealInterstitialDelegate

extension ViewController: AppodealInterstitialDelegate {
    func interstitialWillPresent(){
        AppAnalyticsHelper.sendAppAnalyticEvent(withName: "Show_interstitial")
    }
    func interstitialDidDismiss(){
        rulerScreenNavigationHelper.showSettingsScreen()
        session.run(sessionConfiguration)
    }
    func interstitialDidClick(){
        AppAnalyticsHelper.sendAppAnalyticEvent(withName: "User_click_interstitial")
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
    
    func setUpMessageLabel() {
        if lines.count > 0 {
            var polygonLength: Float = 0.0
            for line in self.lines {
                polygonLength = polygonLength + line.lineLength()
            }
            if currentLine != nil {
                polygonLength += (currentLine?.lineLength())!
            }
            
            let measureText = String(format: "%.2f %@", polygonLength, unit.unit)
            messageLabel.text = measureText
            rulerAppleWatchHelper.sendMeasureToWatch(measure: measureText)
            
            if ((currentLine?.lastLineStartVector) != nil) {
                angleLabel.text = (currentLine?.getAngleBetween3Vectors())!
            }
            
        } else {
            messageLabel.text = currentLine?.distance(to: endValue) ?? NSLocalizedString("сalculating", comment: "")
            
            if let text = messageLabel.text {
                rulerAppleWatchHelper.sendMeasureToWatch(measure: text)
            }
            
            angleLabel.text = ""
        }
    }
}
