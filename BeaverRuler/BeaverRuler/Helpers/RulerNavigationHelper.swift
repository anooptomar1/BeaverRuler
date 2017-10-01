//
//  RulerScreenNavigationHelper.swift
//  BeaverRuler
//
//  Created by user on 9/30/17.
//  Copyright © 2017 Sasha. All rights reserved.
//

import Foundation
import UIKit
import Crashlytics

class RulerNavigationHelper {
    
    var rulerScreen: ViewController!
    
    func showSettingsScreen() {
        
        AppAnalyticsHelper.sendAppAnalyticEvent(withName: "Show_settings_pressed")
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        guard let settingsViewController = storyboard.instantiateViewController(withIdentifier: "SettingsController") as? SettingsController else {
            return
        }
        
        let barButtonItem = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(dismissSettings))
        settingsViewController.navigationItem.rightBarButtonItem = barButtonItem
        settingsViewController.title = NSLocalizedString("settingsScreenTitle", comment: "")
        settingsViewController.products = rulerScreen.products
        
        let navigationController = UINavigationController(rootViewController: settingsViewController)
        navigationController.modalPresentationStyle = .popover
        navigationController.popoverPresentationController?.delegate = rulerScreen
        navigationController.preferredContentSize = CGSize(width: rulerScreen.sceneView.bounds.size.width - 20, height: rulerScreen.sceneView.bounds.size.height - 50)
        rulerScreen.present(navigationController, animated: true, completion: nil)
        
        navigationController.popoverPresentationController?.sourceView = rulerScreen.settingsButton
        navigationController.popoverPresentationController?.sourceRect = rulerScreen.settingsButton.bounds
        
    }
    
    func showGalleryScreen() {
        AppAnalyticsHelper.sendAppAnalyticEvent(withName: "Show_user_gallery_pressed")
        
        rulerScreen.tutorialHelper.finishTutorial()
        
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        guard let settingsViewController = storyboard.instantiateViewController(withIdentifier: "ObjectsFoldersViewController") as? ObjectsFoldersViewController else {
            return
        }
        
        settingsViewController.products = rulerScreen.products
        settingsViewController.apdAdQueue = rulerScreen.apdAdQueue
        let barButtonItem = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(dismissSettings))
        settingsViewController.navigationItem.rightBarButtonItem = barButtonItem
        settingsViewController.title = NSLocalizedString("userGalleryScreenTitle", comment: "")
        
        let navigationController = UINavigationController(rootViewController: settingsViewController)
        navigationController.modalPresentationStyle = .popover
        navigationController.popoverPresentationController?.delegate = rulerScreen
        navigationController.preferredContentSize = CGSize(width: rulerScreen.sceneView.bounds.size.width - 20, height: rulerScreen.sceneView.bounds.size.height - 50)
        rulerScreen.present(navigationController, animated: true, completion: nil)
        
        navigationController.popoverPresentationController?.sourceView = rulerScreen.galleryButton
        navigationController.popoverPresentationController?.sourceRect = rulerScreen.galleryButton.bounds
    }
    
    @objc
    func dismissSettings() {
        rulerScreen.dismiss(animated: true, completion: nil)
        updateSettings()
    }
    
    private func updateSettings() {
        let defaults = UserDefaults.standard
        rulerScreen.unit = DistanceUnit(rawValue: defaults.string(forKey: Setting.measureUnits.rawValue)!)!
    }
    
}
