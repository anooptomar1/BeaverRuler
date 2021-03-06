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
    let finishDraggingTutorialKey = "finishDraggingTutorialTutorialKey"
    fileprivate var isFinishTutorial = false
    fileprivate var isFinishDraggingTutorial = false
    fileprivate var tutorialStep = 0
    
    var tutorialStep1Image: UIImageView!
    var tutorialStep2Image: UIImageView!
    var tutorialStep3Image: UIImageView!
    var tutorialStep4Image: UIImageView!
    var tutorialStep5Image: UIImageView!
    var tutorialStep6Image: UIImageView!
    var draggingTutorialImage: UIImageView!
    
    let makeSecondPointTutorialTime = Double(4)
    var timer = Timer()
    var showSecondPointTutorial = false
    
    init() {
        let defaults = UserDefaults.standard
        isFinishTutorial = defaults.bool(forKey: finishTutorialKey)
        isFinishDraggingTutorial = defaults.bool(forKey: finishDraggingTutorialKey)
    }
    
    func setUpTutorialStep1() {
        if isFinishTutorial {
            tutorialStep1Image.isHidden = true
            tutorialStep2Image.isHidden = true
            tutorialStep4Image.isHidden = true
            tutorialStep5Image.isHidden = true
            tutorialStep6Image.isHidden = true
            draggingTutorialImage.isHidden = true
        } else {
            tutorialStep1Image.isHidden = false
            tutorialStep2Image.isHidden = true
            tutorialStep4Image.isHidden = true
            tutorialStep5Image.isHidden = true
            tutorialStep6Image.isHidden = true
            draggingTutorialImage.isHidden = true
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
    
    func finishBaseTutorial() {
        if isFinishTutorial == false && tutorialStep == 6 {
            tutorialStep6Image.isHidden = true
            isFinishTutorial = true
            
            let defaults = UserDefaults.standard
            defaults.set(isFinishTutorial, forKey: finishTutorialKey)
            AppAnalyticsHelper.sendAppAnalyticEvent(withName: "User_finish_tutorial")
        }
    }
    
    func showDraggingTutorial() {
        if isFinishDraggingTutorial == false {
            draggingTutorialImage.isHidden = false
        }
    }
    
    func hideDraggingTutorial() {
        draggingTutorialImage.isHidden = true
    }
    
    func finishDraggingTutorial() {
        if isFinishDraggingTutorial == false {
            hideDraggingTutorial()
            isFinishDraggingTutorial = true
            let defaults = UserDefaults.standard
            defaults.set(isFinishDraggingTutorial, forKey: finishDraggingTutorialKey)
            AppAnalyticsHelper.sendAppAnalyticEvent(withName: "User_finish_dragging_tutorial")
        }
    }
    
}
