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
    var tutorialStep5Image: UIImageView!
    var tutorialStep6Image: UIImageView!
    var tutorialStep7Image: UIImageView!
    var tutorialStep8Image: UIImageView!
    
    let makeSecondPointTutorialTime = Double(4)
    var timer = Timer()
    var showSecondPointTutorial = false
    
    init() {
        let defaults = UserDefaults.standard
        isFinishTutorial = defaults.bool(forKey: finishTutorialKey)
    }
    
    func setUpTutorialStep1() {
        if isFinishTutorial {
            tutorialStep1Image.isHidden = true
            tutorialStep2Image.isHidden = true
            tutorialStep4Image.isHidden = true
            tutorialStep5Image.isHidden = true
            tutorialStep6Image.isHidden = true
            tutorialStep7Image.isHidden = true
            tutorialStep8Image.isHidden = true
        } else {
            tutorialStep1Image.isHidden = false
            tutorialStep2Image.isHidden = true
            tutorialStep4Image.isHidden = true
            tutorialStep5Image.isHidden = true
            tutorialStep6Image.isHidden = true
            tutorialStep7Image.isHidden = true
            tutorialStep8Image.isHidden = true
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
            timer = Timer.scheduledTimer(timeInterval: makeSecondPointTutorialTime, target: self,   selector: (#selector(TutorialHelper.finishTimer)), userInfo: nil, repeats: false)
            tutorialStep2Image.isHidden = true
            tutorialStep = 3
            AppAnalyticsHelper.sendAppAnalyticEvent(withName: "User_finish_tutorial_step_2")
        }
    }
    
    @objc func finishTimer() {
        tutorialStep2Image.isHidden = false
        showSecondPointTutorial = true
    }
    
    func setUpTutorialStep4() {
        if isFinishTutorial == false && tutorialStep == 3 {
            tutorialStep2Image.isHidden = true
            tutorialStep4Image.isHidden = false
            tutorialStep = 4
            AppAnalyticsHelper.sendAppAnalyticEvent(withName: "User_finish_tutorial_step_3")
        }
    }
    
    func setUpTutorialStep5() {
        if isFinishTutorial == false && tutorialStep == 4 {
            tutorialStep4Image.isHidden = true
            tutorialStep5Image.isHidden = false
            tutorialStep = 5
            AppAnalyticsHelper.sendAppAnalyticEvent(withName: "User_finish_tutorial_step_4")
        }
    }
    
    func setUpTutorialStep6() {
        if isFinishTutorial == false && tutorialStep == 5 {
            tutorialStep5Image.isHidden = true
            tutorialStep6Image.isHidden = false
            tutorialStep = 6
            AppAnalyticsHelper.sendAppAnalyticEvent(withName: "User_finish_tutorial_step_5")
        }
    }
    
    func setUpTutorialStep7() {
        if isFinishTutorial == false && tutorialStep == 6 {
            tutorialStep6Image.isHidden = true
            tutorialStep7Image.isHidden = false
            tutorialStep = 7
            AppAnalyticsHelper.sendAppAnalyticEvent(withName: "User_finish_tutorial_step_6")
        }
    }
    
    func setUpTutorialStep8() {
        if isFinishTutorial == false && tutorialStep == 7 {
            tutorialStep7Image.isHidden = true
            tutorialStep8Image.isHidden = false
            tutorialStep = 8
            AppAnalyticsHelper.sendAppAnalyticEvent(withName: "User_finish_tutorial_step_7")
        }
    }
    
    func finishTutorial() {
        if isFinishTutorial == false && tutorialStep == 8 {
            tutorialStep8Image.isHidden = true
            isFinishTutorial = true
            
            let defaults = UserDefaults.standard
            defaults.set(isFinishTutorial, forKey: finishTutorialKey)
            AppAnalyticsHelper.sendAppAnalyticEvent(withName: "User_finish_tutorial")
        }
    }
}
