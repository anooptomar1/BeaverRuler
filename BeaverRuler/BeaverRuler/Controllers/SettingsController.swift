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
import MessageUI

enum Setting: String {
    case measureUnits = "measureUnits"
}

class SettingsController: UIViewController, MFMailComposeViewControllerDelegate {

    static let removeAdProductId = "com.darkwind.gRuler.removeAd"
    static let removeUserGalleryProductId = "com.darkwind.gRuler.removeAdPlusUserGalleryLimit"
    static let removeAdsPlusLimitProductId = "com.darkwind.gRuler.removeUserGalleryLimit"
    
    @IBOutlet weak var removeAdsButton: UIButton!
    @IBOutlet weak var removeLimitsButton: UIButton!
    @IBOutlet weak var removeAdsPlusLimitButton: UIButton!

    @IBOutlet weak var facebookButtonView: UIView!

    var products = [SKProduct]()
    
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

        let mailComposeViewController = configuredMailComposeViewController()
        if MFMailComposeViewController.canSendMail() {
            self.present(mailComposeViewController, animated: true, completion: nil)
        } else {
            self.showSendMailErrorAlert()
        }

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

    func configuredMailComposeViewController() -> MFMailComposeViewController {
        let mailComposerVC = MFMailComposeViewController()
        mailComposerVC.mailComposeDelegate = self // Extremely important to set the --mailComposeDelegate-- property, NOT the --delegate-- property

        mailComposerVC.setToRecipients(["darkwinddev@gmail.com"])
        mailComposerVC.setSubject("GRuler Feedback/Suggestion")
        mailComposerVC.setMessageBody("Please Enter your message here", isHTML: false)

        return mailComposerVC
    }

    func showSendMailErrorAlert() {
        let sendMailErrorAlert = UIAlertView(title: "Could Not Send Email", message: "Your device could not send e-mail.  Please check e-mail configuration and try again.", delegate: self, cancelButtonTitle: "OK")
        sendMailErrorAlert.show()
    }

    // MARK: MFMailComposeViewControllerDelegate

    func mailComposeController(_ controller: MFMailComposeViewController, didFinishWith result: MFMailComposeResult, error: Error?) {
        controller.dismiss(animated: true)
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
