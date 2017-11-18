//
//  RulerARHelper.swift
//  BeaverRuler
//
//  Created by user on 11/18/17.
//  Copyright © 2017 Sasha. All rights reserved.
//

import Foundation

class RulerARHelper {
    
    var rulerScreen: ViewController!
    
    func detectObjects() {
        
        guard let worldPosition = rulerScreen.sceneView.realWorldVector(screenPosition: rulerScreen.view.center) else { return }
        
        rulerScreen.tutorialHelper.setUpTutorialStep2()
        
        rulerScreen.targetImageView.isHidden = false
        if rulerScreen.lines.isEmpty {
            rulerScreen.messageLabel.text = NSLocalizedString("touchYourPhoneScreen", comment: "")
        }
        rulerScreen.loadingView.stopAnimating()
        rulerScreen.loadingView.isHidden = true
        if rulerScreen.isMeasuring {
            if rulerScreen.showCurrentLine {
                rulerScreen.currentLine?.showLine()
                if rulerScreen.startValue == rulerScreen.vectorZero {
                    rulerScreen.startValue = worldPosition
                    rulerScreen.currentLine = RulerLine(sceneView: rulerScreen.sceneView, startVector: rulerScreen.startValue, unit: rulerScreen.unit)
                }
                
                rulerScreen.endValue = rulerScreen.rulerMeasurementsHelper.getEndValue(worldPosition: worldPosition)
                rulerScreen.currentLine?.unit = rulerScreen.unit
                rulerScreen.currentLine?.update(to: rulerScreen.endValue)
                rulerScreen.setUpMessageLabel()
            } else {
                rulerScreen.currentLine?.hideLine()
                
                if rulerScreen.userDraggingPoint == false {
                    selectNearestPoint()
                } else {
                    rulerScreen.updateSelectedLines()
                }
            }
            
        } else {
            if rulerScreen.userDraggingPoint == false {
                selectNearestPoint()
            } else {
                rulerScreen.tutorialHelper.finishDraggingTutorial()
                rulerScreen.updateSelectedLines()
            }
        }
    }
    
    func selectNearestPoint() {
        
        rulerScreen.tutorialHelper.hideDraggingTutorial()
        
        guard let worldPosition = rulerScreen.sceneView.realWorldVector(screenPosition: rulerScreen.view.center) else { return }
        
        RulerLine.diselectNode(node: rulerScreen.startSelectedNode)
        RulerLine.diselectNode(node: rulerScreen.endSelectedNode)
        rulerScreen.startNodeLine = nil
        rulerScreen.endNodeLine = nil
        rulerScreen.endSelectedNode = nil
        rulerScreen.startSelectedNode = nil
        
        
        for (index, line) in rulerScreen.lines.enumerated() {
            
            if let startVector = line.startVector {
                let distanceToStartPoint = rulerScreen.rulerMeasurementsHelper.distanceBetweenPoints(firtsPoint: rulerScreen.sceneView.projectPoint(worldPosition), secondPoint: rulerScreen.sceneView.projectPoint(startVector))
                
                if distanceToStartPoint < 20  {
                    print("selectStartPointForLine: \(index)")
                    RulerLine.selectNode(node: line.startNode)
                    rulerScreen.startSelectedNode = line.startNode
                    rulerScreen.startNodeLine = line
                }
            }
            
            if let endVector = line.endVector {
                let distanceToEndPoint = rulerScreen.rulerMeasurementsHelper.distanceBetweenPoints(firtsPoint: rulerScreen.sceneView.projectPoint(worldPosition), secondPoint: rulerScreen.sceneView.projectPoint(endVector))
                
                if distanceToEndPoint < 20  {
                    print("selectEndPointForLine: \(index)")
                    RulerLine.selectNode(node: line.endNode)
                    rulerScreen.endSelectedNode = line.endNode
                    rulerScreen.endNodeLine = line
                }
            }
            
            if rulerScreen.startNodeLine != nil || rulerScreen.endNodeLine != nil {
                rulerScreen.tutorialHelper.showDraggingTutorial()
            }
        }
    }
}
