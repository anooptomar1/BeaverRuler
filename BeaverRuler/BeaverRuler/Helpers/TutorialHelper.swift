//
//  TutorialHelper.swift
//  BeaverRuler
//
//  Created by user on 9/29/17.
//  Copyright © 2017 Sasha. All rights reserved.
//

import Foundation
import UIKit
import Crashlytics

class TutorialHelper {
    
    let finishTutorialKey = "finishTutorialKey"
    fileprivate var isFinishTutorial = false
    fileprivate var tutorialStep = 0
    
    var tutorialStep1Image: UIImageView!
    var tutorialStep2Image: UIImageView!
    var tutorialStep3Image: UIImageView!
    var tutorialStep4Image: UIImageView!
    
    init() {
        let defaults = UserDefaults.standard
        isFinishTutorial = defaults.bool(forKey: finishTutorialKey)
    }
    
    func setUpTutorialStep1() {
        if isFinishTutorial {
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
            AppAnalyticsHelper.sendAppAnalyticEvent(withName: "User_start_tutorial")
        }
    }
    
    func setUpTutorialStep2() {
        if isFinishTutorial == false && tutorialStep == 1 {
            tutorialStep1Image.isHidden = true
            tutorialStep2Image.isHidden = false
            tutorialStep = 2
            AppAnalyticsHelper.sendAppAnalyticEvent(withName: "User_finish_tutorial_step_1")
        }
    }
    
    func setUpTutorialStep3() {
        if isFinishTutorial == false && tutorialStep == 2 {
            tutorialStep2Image.isHidden = true
            tutorialStep3Image.isHidden = false
            tutorialStep = 3
            AppAnalyticsHelper.sendAppAnalyticEvent(withName: "User_finish_tutorial_step_2")
        }
    }
    
    func setUpTutorialStep4() {
        if isFinishTutorial == false && tutorialStep == 3 {
            tutorialStep3Image.isHidden = true
            tutorialStep4Image.isHidden = false
            tutorialStep = 4
            AppAnalyticsHelper.sendAppAnalyticEvent(withName: "User_finish_tutorial_step_3")
        }
    }
    
    func finishTutorial() {
        if isFinishTutorial == false && tutorialStep == 4 {
            tutorialStep4Image.isHidden = true
            isFinishTutorial = true
            
            let defaults = UserDefaults.standard
            defaults.set(isFinishTutorial, forKey: finishTutorialKey)
            AppAnalyticsHelper.sendAppAnalyticEvent(withName: "User_finish_tutorial")
        }
    }
}
