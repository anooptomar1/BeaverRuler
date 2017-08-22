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

class ViewController: UIViewController {

    @IBOutlet var sceneView: ARSCNView!
    @IBOutlet weak var targetImageView: UIImageView!
    @IBOutlet weak var loadingView: UIActivityIndicatorView!
    @IBOutlet weak var messageLabel: UILabel!
    @IBOutlet weak var settingsButton: UIButton!
    @IBOutlet weak var resetButton: UIButton!

    fileprivate lazy var session = ARSession()
    fileprivate lazy var sessionConfiguration = ARWorldTrackingSessionConfiguration()
    fileprivate lazy var isMeasuring = false;
    fileprivate lazy var vectorZero = SCNVector3()
    fileprivate lazy var startValue = SCNVector3()
    fileprivate lazy var endValue = SCNVector3()
    fileprivate lazy var lines: [RulerLine] = []
    fileprivate var currentLine: RulerLine?
    fileprivate lazy var unit: DistanceUnit = .centimeter
    fileprivate var alertController: UIAlertController?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupScene()
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
            resetValues()
            isMeasuring = true
            targetImageView.image = UIImage(named: "targetGreen")

        } else {

            if let line = currentLine {
                lines.append(line)
                currentLine = RulerLine(sceneView: sceneView, startVector: endValue, unit: unit)
                //currentLine = nil
            }
        }
    }

    // MARK: - Users Interactions

    @IBAction func finishPolygonPressed(_ sender: Any) {
        if currentLine != nil {
            isMeasuring = false
            targetImageView.image = UIImage(named: "targetWhite")
            if currentLine != nil {
                currentLine?.removeFromParentNode()
                currentLine = nil
            }
        }
    }

    @IBAction func undoPressed(_ sender: Any) {

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

            }

        }

    }

    @IBAction func showSettings(_ sender: Any) {


        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        guard let settingsViewController = storyboard.instantiateViewController(withIdentifier: "SettingsController") as? SettingsController else {
            return
        }

        let barButtonItem = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(dismissSettings))
        settingsViewController.navigationItem.rightBarButtonItem = barButtonItem
        settingsViewController.title = "Options"

        let navigationController = UINavigationController(rootViewController: settingsViewController)
        navigationController.modalPresentationStyle = .popover
        navigationController.popoverPresentationController?.delegate = self
        navigationController.preferredContentSize = CGSize(width: sceneView.bounds.size.width - 20, height: sceneView.bounds.size.height - 50)
        self.present(navigationController, animated: true, completion: nil)

        navigationController.popoverPresentationController?.sourceView = settingsButton
        navigationController.popoverPresentationController?.sourceRect = settingsButton.bounds

        





//        let alertVC = UIAlertController(title: "Settings", message: "Please select distance unit options", preferredStyle: .actionSheet)
//        alertVC.addAction(UIAlertAction(title: DistanceUnit.centimeter.title, style: .default) { [weak self] _ in
//            self?.unit = .centimeter
//        })
//        alertVC.addAction(UIAlertAction(title: DistanceUnit.inch.title, style: .default) { [weak self] _ in
//            self?.unit = .inch
//        })
//        alertVC.addAction(UIAlertAction(title: DistanceUnit.meter.title, style: .default) { [weak self] _ in
//            self?.unit = .meter
//        })
//        alertVC.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
//        present(alertVC, animated: true, completion: nil)

    }

    @objc
    func dismissSettings() {
        self.dismiss(animated: true, completion: nil)
        updateSettings()
    }

    private func updateSettings() {
        let defaults = UserDefaults.standard

        self.unit = DistanceUnit(rawValue: defaults.string(forKey: Setting.measureUnits.rawValue)!)!

        //self.unit = defaults.integer(forKey: Setting.measureUnits.rawValue) as DistanceUnit

//        showDebugVisuals = defaults.bool(for: .debugMode)
//        toggleAmbientLightEstimation(defaults.bool(for: .ambientLightEstimation))
//        dragOnInfinitePlanesEnabled = defaults.bool(for: .dragOnInfinitePlanes)
//        showHitTestAPIVisualization = defaults.bool(for: .showHitTestAPI)
//        use3DOFTracking    = defaults.bool(for: .use3DOFTracking)
//        use3DOFTrackingFallback = defaults.bool(for: .use3DOFFallback)
//        for (_, plane) in planes {
//            plane.updateOcclusionSetting()
//        }
    }

    @IBAction func resetButtonTapped(_ sender: Any) {
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

        let takeScreenshotBlock = {
            UIImageWriteToSavedPhotosAlbum(self.sceneView.snapshot(), nil, nil, nil)
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

}

// MARK: - ARSCNViewDelegate

extension ViewController: ARSCNViewDelegate {
    func renderer(_ renderer: SCNSceneRenderer, updateAtTime time: TimeInterval) {
        DispatchQueue.main.async { [weak self] in
            self?.detectObjects()
        }
    }

    func session(_ session: ARSession, didFailWithError error: Error) {
        messageLabel.text = "Error occurred"
    }

    func sessionWasInterrupted(_ session: ARSession) {
        messageLabel.text = "Interrupted"
    }

    func sessionInterruptionEnded(_ session: ARSession) {
        messageLabel.text = "Interruption ended"
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
        targetImageView.isHidden = false
        settingsButton.isHidden = false
        if lines.isEmpty {
            messageLabel.text = "Hold screen & move your phone…"
        }
        loadingView.stopAnimating()
        if isMeasuring {
            if startValue == vectorZero {
                startValue = worldPosition
                currentLine = RulerLine(sceneView: sceneView, startVector: startValue, unit: unit)
            }

            endValue = getEndValue(worldPosition: worldPosition)
            //endValue = worldPosition

            currentLine?.update(to: endValue)
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
