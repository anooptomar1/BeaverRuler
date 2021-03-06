//
//  SettingsController.swift
//  BeaverRuler
//
//  Created by Aleksandr Khotyashov on 8/22/17.
//  Copyright © 2017 Sasha. All rights reserved.
//

import UIKit
import StoreKit
import Crashlytics
import FacebookCore
import FacebookLogin
import OneSignal

enum Setting: String {
    case measureUnits = "measureUnits"
}

class SettingsController: UIViewController {

    static let removeAdProductId = "com.darkwind.gRuler.removeAd"
    static let removeUserGalleryProductId = "com.darkwind.gRuler.removeUserGalleryLimit"
    static let removeAdsPlusLimitProductId = "com.darkwind.gRuler.removeAdPlusUserGalleryLimit"
    
    @IBOutlet weak var facebookButtonView: UIView!
    @IBOutlet weak var measureUnitsButton: UIButton!
    @IBOutlet weak var subscribeToNewsButton: UIButton!
    
    var products = [SKProduct]()
    let appFeedbackHelper = AppFeedbackHelper()
    
    override func viewDidLoad() {
        super.viewDidLoad()

        AppAnalyticsHelper.sendAppAnalyticEvent(withName: "Settings_Screen")

        let loginButton = LoginButton(frame: CGRect(origin: CGPoint(x:0,y:0), size: facebookButtonView.bounds.size) ,readPermissions: [ ReadPermission.publicProfile ])

        facebookButtonView.addSubview(loginButton)
        setUpButtons()
    }
    
    func setUpButtons() {
        setupButtonStyle(button: measureUnitsButton)
        setupButtonStyle(button: subscribeToNewsButton)
        
        measureUnitsButton.setTitle(NSLocalizedString("measureUnitsButtonTitle", comment: ""), for: [])
        subscribeToNewsButton.setTitle(NSLocalizedString("subscribeToNews", comment: ""), for: [])
        
    }
    
    func setupButtonStyle(button: UIButton) {
        button.layer.cornerRadius = 10
        button.layer.borderWidth = 1
        button.layer.borderColor = measureUnitsButton.backgroundColor?.cgColor
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    // MARK: - Users Interactions

    @IBAction func loginFacebookPressed(_ sender: Any) {
        AppAnalyticsHelper.sendAppAnalyticEvent(withName: "Login_Facebook_pressed")

        let loginManager = LoginManager()
        loginManager.logIn([ ReadPermission.publicProfile ], viewController: self) { loginResult in
            switch loginResult {
            case .failed(let error):
                print(error)
            case .cancelled:
                print("User cancelled login.")
            case .success( _, _, _):
                print("Logged in!")
            }
        }
    }
    
    @IBAction func subscribeToNewsPressed(_ sender: Any) {
        
        let status: OSPermissionSubscriptionState = OneSignal.getPermissionSubscriptionState()
        let hasPrompted = status.permissionStatus.hasPrompted
        
        if hasPrompted {
            showProposalToGoAppSettings()
        } else {
            AppAnalyticsHelper.sendAppAnalyticEvent(withName: "Show_push_notification_proposal_Settings_screen")
            OneSignal.promptForPushNotifications(userResponse: { accepted in
                AppAnalyticsHelper.sendAppAnalyticEvent(withName: "User_accepted_push_notifications_Settings_screen_\(accepted)")
            })
        }
        
    }
    
    func showProposalToGoAppSettings() {
        AppAnalyticsHelper.sendAppAnalyticEvent(withName: "Show_go_to_app_settings_notifications")
        
        let alert = UIAlertController(title: NSLocalizedString("GRulerWouldLikeToAccessNotifications", comment: ""), message: NSLocalizedString("pleaseGrantPermissionToUseNotifications", comment: ""), preferredStyle: .alert )
        alert.addAction(UIAlertAction(title: NSLocalizedString("openSettings", comment: ""), style: .default) { alert in
            
            AppAnalyticsHelper.sendAppAnalyticEvent(withName: "User_go_to_app_settings_notifications")
            
            UIApplication.shared.open(URL(string: UIApplicationOpenSettingsURLString)!, options: [:], completionHandler: { (success) in
            })
            
        })
        
        let cancelAction = UIAlertAction(title: NSLocalizedString("notNowKey", comment: ""), style: .cancel, handler: { (action) -> Void in
            AppAnalyticsHelper.sendAppAnalyticEvent(withName: "Subscribe_notifications_cancel_Settings_screen")
        })
        
        alert.addAction(cancelAction)
        
        present(alert, animated: true, completion: nil)
    }

    @IBAction func measureUnitPressed(_ sender: Any) {
        
        AppAnalyticsHelper.sendAppAnalyticEvent(withName: "Change_measure_unit_pressed")

        let defaults = UserDefaults.standard

        let alertVC = UIAlertController(title: NSLocalizedString("settingsScreenTitle", comment: ""), message: NSLocalizedString("pleaseSelectDistanceUnitOptions", comment: ""), preferredStyle: .actionSheet)
        alertVC.addAction(UIAlertAction(title: DistanceUnit.centimeter.title, style: .default) { [weak self] _ in
            defaults.set(DistanceUnit.centimeter.rawValue, forKey: Setting.measureUnits.rawValue)
        })
        alertVC.addAction(UIAlertAction(title: DistanceUnit.inch.title, style: .default) { [weak self] _ in
            defaults.set(DistanceUnit.inch.rawValue, forKey: Setting.measureUnits.rawValue)
        })
        alertVC.addAction(UIAlertAction(title: DistanceUnit.meter.title, style: .default) { [weak self] _ in
            defaults.set(DistanceUnit.meter.rawValue, forKey: Setting.measureUnits.rawValue)
        })
        
        alertVC.addAction(UIAlertAction(title: NSLocalizedString("cancelKey", comment: ""), style: .cancel, handler: nil))
        present(alertVC, animated: true, completion: nil)

    }

}
