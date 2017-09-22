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

enum Setting: String {
    case measureUnits = "measureUnits"
}

class SettingsController: UIViewController {

    static let removeAdProductId = "com.darkwind.gRuler.removeAd"
    static let removeUserGalleryProductId = "com.darkwind.gRuler.removeAdPlusUserGalleryLimit"
    static let removeAdsPlusLimitProductId = "com.darkwind.gRuler.removeUserGalleryLimit"
    
    @IBOutlet weak var removeAdsButton: UIButton!
    @IBOutlet weak var removeLimitsButton: UIButton!
    @IBOutlet weak var removeAdsPlusLimitButton: UIButton!
    @IBOutlet weak var facebookButtonView: UIView!
    @IBOutlet weak var measureUnitsButton: UIButton!
    @IBOutlet weak var restorePurchasesButton: UIButton!
    @IBOutlet weak var rateAppButton: UIButton!
    @IBOutlet weak var sendFeedbackButton: UIButton!
    
    
    var products = [SKProduct]()
    let appFeedbackHelper = AppFeedbackHelper()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        NotificationCenter.default.addObserver(self, selector: #selector(SettingsController.handlePurchaseNotification(_:)),
                                               name: NSNotification.Name(rawValue: IAPHelper.IAPHelperPurchaseNotification),
                                               object: nil)
        
        if RageProducts.store.isProductPurchased(SettingsController.removeAdProductId) {
             removeAdsButton.isHidden = true
        }
        
        if RageProducts.store.isProductPurchased(SettingsController.removeUserGalleryProductId) {
             removeLimitsButton.isHidden = true
        }
        
        if RageProducts.store.isProductPurchased(SettingsController.removeAdsPlusLimitProductId) {
            removeAdsButton.isHidden = true
            removeLimitsButton.isHidden = true
        }

        AppAnalyticsHelper.sendAppAnalyticEvent(withName: "Settings Screen")

        let loginButton = LoginButton(frame: CGRect(origin: CGPoint(x:0,y:0), size: facebookButtonView.bounds.size) ,readPermissions: [ ReadPermission.publicProfile ])

        facebookButtonView.addSubview(loginButton)
        setUpButtons()
    }
    
    func setUpButtons() {
        setupButtonStyle(button: removeAdsButton)
        setupButtonStyle(button: removeLimitsButton)
        setupButtonStyle(button: removeAdsPlusLimitButton)
        setupButtonStyle(button: measureUnitsButton)
        setupButtonStyle(button: restorePurchasesButton)
        setupButtonStyle(button: rateAppButton)
        setupButtonStyle(button: sendFeedbackButton)
    }
    
    func setupButtonStyle(button: UIButton) {
        button.layer.cornerRadius = 10
        button.layer.borderWidth = 1
        button.layer.borderColor = rateAppButton.backgroundColor?.cgColor
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    // MARK: - Users Interactions

    @IBAction func loginFacebookPressed(_ sender: Any) {
        AppAnalyticsHelper.sendAppAnalyticEvent(withName: "Login Facebook pressed")

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

    @IBAction func sendFeedbackPressed(_ sender: Any) {
        AppAnalyticsHelper.sendAppAnalyticEvent(withName: "Send feedback pressed")
        appFeedbackHelper.showFeedback()
    }
    
    @IBAction func rateAppPressed(_ sender: Any) {
        AppAnalyticsHelper.sendAppAnalyticEvent(withName: "Rate app pressed(Settings screen)")
        RateAppHelper.rateApp()
    }
    
    @IBAction func restoreTapped(_ sender: Any) {
        RageProducts.store.restorePurchases()
        AppAnalyticsHelper.sendAppAnalyticEvent(withName: "Restore purchases pressed")
    }

    @IBAction func measureUnitPressed(_ sender: Any) {
        
        AppAnalyticsHelper.sendAppAnalyticEvent(withName: "Change measure unit pressed")

        let defaults = UserDefaults.standard

        let alertVC = UIAlertController(title: "Settings", message: "Please select distance unit options", preferredStyle: .actionSheet)
        alertVC.addAction(UIAlertAction(title: DistanceUnit.centimeter.title, style: .default) { [weak self] _ in
            defaults.set(DistanceUnit.centimeter.rawValue, forKey: Setting.measureUnits.rawValue)
        })
        alertVC.addAction(UIAlertAction(title: DistanceUnit.inch.title, style: .default) { [weak self] _ in
            defaults.set(DistanceUnit.inch.rawValue, forKey: Setting.measureUnits.rawValue)
        })
        alertVC.addAction(UIAlertAction(title: DistanceUnit.meter.title, style: .default) { [weak self] _ in
            defaults.set(DistanceUnit.meter.rawValue, forKey: Setting.measureUnits.rawValue)
        })
        alertVC.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        present(alertVC, animated: true, completion: nil)

    }

    @IBAction func removeAdsPressed(_ sender: Any) {
        for (_, product) in products.enumerated() {
            if product.productIdentifier == SettingsController.removeAdProductId {
                RageProducts.store.buyProduct(product)
                AppAnalyticsHelper.sendAppAnalyticEvent(withName: "Remove ad pressed")
                break
            }
        }
    }
    
    @IBAction func removeLimitsPressed(_ sender: Any) {
        for (index, product) in products.enumerated() {
            if product.productIdentifier == SettingsController.removeUserGalleryProductId {
                RageProducts.store.buyProduct(product)
                AppAnalyticsHelper.sendAppAnalyticEvent(withName: "Remove objects limit pressed(Settings screen)")
                break
            }
        }
    }
    
    @IBAction func removeAdsPlusLimitPressed(_ sender: Any) {
        for (index, product) in products.enumerated() {
            if product.productIdentifier == SettingsController.removeAdsPlusLimitProductId {
                RageProducts.store.buyProduct(product)
                AppAnalyticsHelper.sendAppAnalyticEvent(withName: "Remove ad objects limit pressed")
                break
            }
        }
    }

    @objc func handlePurchaseNotification(_ notification: Notification) {
        guard let productID = notification.object as? String else { return }
        
        if productID == SettingsController.removeAdProductId {
            removeAdsButton.isHidden = true
            self.logPurchase(name: "Remove ad", id: productID, price: 1.99)
            AppAnalyticsHelper.sendAppAnalyticEvent(withName: "User buy remove ad")
        }
        
        if productID == SettingsController.removeUserGalleryProductId {
            removeLimitsButton.isHidden = true
            self.logPurchase(name: "Remove object limit", id: productID, price: 1.99)
            AppAnalyticsHelper.sendAppAnalyticEvent(withName: "User buy remove objects limits(Settinds screen)")
        }
        
        if productID == SettingsController.removeAdsPlusLimitProductId {
            removeAdsButton.isHidden = true
            removeLimitsButton.isHidden = true
            self.logPurchase(name: "Remove ad and objects limit", id: productID, price: 2.99)
            AppAnalyticsHelper.sendAppAnalyticEvent(withName: "User buy remove ad and objects limit")
        }
    }
    
    func logPurchase(name: String, id: String, price: NSDecimalNumber) {
        Answers.logPurchase(withPrice: price,
                            currency: "USD",
                            success: true,
                            itemName: name,
                            itemType: "In app",
                            itemId: id,
                            customAttributes: [:])
    }

}
