//
//  RulerPurchasesHelper.swift
//  BeaverRuler
//
//  Created by user on 10/1/17.
//  Copyright © 2017 Sasha. All rights reserved.
//

import Foundation
import Crashlytics
import UIKit

class RulerPurchasesHelper {
    
    private var rulerScreen: ViewController!
    
    init(rulerScreen: ViewController) {
        
        self.rulerScreen = rulerScreen
        
        NotificationCenter.default.addObserver(self, selector: #selector(RulerPurchasesHelper.handlePurchaseNotification(_:)),
                                               name: NSNotification.Name(rawValue: IAPHelper.IAPHelperPurchaseNotification),
                                               object: nil)
        
        loadInAppsPurchases()
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
            rulerScreen.removeObjectsLimit = true
        }
        
        if productID == SettingsController.removeAdProductId {
            self.logPurchase(name: "Remove ad", id: productID, price: 1.99)
            AppAnalyticsHelper.sendAppAnalyticEvent(withName: "User_buy_remove_ad")
        }
        
        if productID == SettingsController.removeAdsPlusLimitProductId {
            self.logPurchase(name: "Remove ad and objects limit", id: productID, price: 2.99)
            AppAnalyticsHelper.sendAppAnalyticEvent(withName: "User_buy_remove_ad_and_objects_limit")
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
    
    func loadInAppsPurchases() {
        if RageProducts.store.isProductPurchased(SettingsController.removeUserGalleryProductId) || RageProducts.store.isProductPurchased(SettingsController.removeAdsPlusLimitProductId) {
            rulerScreen.removeObjectsLimit = true
        }
        
        if (RageProducts.store.isProductPurchased(SettingsController.removeAdProductId)) || (RageProducts.store.isProductPurchased(SettingsController.removeAdsPlusLimitProductId)) {
            
        } else {
            rulerScreen.apdAdQueue.setMaxAdSize(rulerScreen.capacity)
            rulerScreen.apdAdQueue.loadAd(of: rulerScreen.type)
        }
        
        rulerScreen.products = []
        RageProducts.store.requestProducts{success, products in
            if success {
                self.rulerScreen.products = products!
            }
        }
    }
    
    func showPurchasesPopUp() {
        let message = NSLocalizedString("purchasesPopUpMessage", comment: "")
        let rateAlert = UIAlertController(title: NSLocalizedString("purchasesPopUpTitle", comment: "") + "\u{1F4B0}", message: message, preferredStyle: .alert)
        let removeAdsPlusLimitAction = UIAlertAction(title: NSLocalizedString("removeAdsPlusLimitButtonTitle", comment: ""), style: .default, handler: { (action) -> Void in
            self.buyProduct(productId: SettingsController.removeAdsPlusLimitProductId)
            AppAnalyticsHelper.sendAppAnalyticEvent(withName: "Remove_ad_objects_limit_AfterRateButton_pressed")
        })
        
        let removeAdsAction = UIAlertAction(title: NSLocalizedString("removeAdsButtonTitle", comment: ""), style: .default, handler: { (action) -> Void in
            self.buyProduct(productId: SettingsController.removeAdProductId)
            AppAnalyticsHelper.sendAppAnalyticEvent(withName: "Remove_ad_AfterRateButton_pressed")
        })
        
        let removeLimitAction = UIAlertAction(title: NSLocalizedString("removeLimitButtonTitle", comment: ""), style: .default, handler: { (action) -> Void in
            self.buyProduct(productId: SettingsController.removeUserGalleryProductId)
            AppAnalyticsHelper.sendAppAnalyticEvent(withName: "Remove_objects_limit_AfterRateButton_pressed")
        })
        
        let restorePurchasesAction = UIAlertAction(title: NSLocalizedString("restorePurchasesButtonTitle", comment: ""), style: .default, handler: { (action) -> Void in
            RageProducts.store.restorePurchases()
            AppAnalyticsHelper.sendAppAnalyticEvent(withName: "Restore_purchases_pressed")
        })
        
        let cancelAction = UIAlertAction(title: NSLocalizedString("cancelKey", comment: ""), style: .cancel, handler: { (action) -> Void in
            AppAnalyticsHelper.sendAppAnalyticEvent(withName: "Rate_app_cancel_purchase_AfterRateButton_pressed")
        })
        
        if !RageProducts.store.isProductPurchased(SettingsController.removeAdsPlusLimitProductId) {
            rateAlert.addAction(removeAdsPlusLimitAction)
        }
        
        if !RageProducts.store.isProductPurchased(SettingsController.removeAdProductId){
            rateAlert.addAction(removeAdsAction)
        }
        
        if !RageProducts.store.isProductPurchased(SettingsController.removeUserGalleryProductId) {
            rateAlert.addAction(removeLimitAction)
        }
        
        rateAlert.addAction(restorePurchasesAction)
        rateAlert.addAction(cancelAction)
        
        DispatchQueue.main.async {
            self.rulerScreen.present(rateAlert, animated: true, completion: nil)
        }
    }
    
    func buyProduct(productId: String) {
        for (_, product) in rulerScreen.products.enumerated() {
            if product.productIdentifier == productId {
                RageProducts.store.buyProduct(product)
                break
            }
        }
        
    }
    
}
