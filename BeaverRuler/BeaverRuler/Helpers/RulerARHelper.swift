//
//  RulerARHelper.swift
//  BeaverRuler
//
//  Created by user on 11/18/17.
//  Copyright © 2017 Sasha. All rights reserved.
//

import Foundation
import SceneKit

class RulerARHelper {
    
    var rulerScreen: ViewController!
    
    func detectObjects() {
        
        if rulerScreen.currentRulerType == RulerType.UsualRuler {
            detectObjectsForUsualRuler()
        }
        
        if rulerScreen.currentRulerType == RulerType.СurveRuler {
            detectObjectsForСurveRuler()
        }
    }
    
    func detectObjectsForUsualRuler() {
        
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
    
    func detectObjectsForСurveRuler() {
        guard let pointOfView = rulerScreen.sceneView.pointOfView else { return }
        
        rulerScreen.tutorialHelper.setUpTutorialStep2()
        rulerScreen.targetImageView.isHidden = false
        
        if rulerScreen.currentCurveLine.curveLine.isEmpty && rulerScreen.curveLines.isEmpty {
            rulerScreen.messageLabel.text = NSLocalizedString("longTouchYourPhoneScreen", comment: "")
        }
        
        rulerScreen.loadingView.stopAnimating()
        rulerScreen.loadingView.isHidden = true
        
        let mat = pointOfView.transform
        let dir = SCNVector3(-1 * mat.m31, -1 * mat.m32, -1 * mat.m33)
        let currentPosition = pointOfView.position + (dir * 0.1)
        
        if rulerScreen.startCurveMeasure {
            
            if rulerScreen.startValue == rulerScreen.vectorZero {
                AppAnalyticsHelper.sendAppAnalyticEvent(withName: "User_make_start_curve_point")
                rulerScreen.startValue = currentPosition
                rulerScreen.endValue = currentPosition
                rulerScreen.currentCurveLine = CurveLine()
                rulerScreen.currentCurveLine.startNode = getPointNode(position: rulerScreen.startValue)
            } else {
                let line = lineFrom(vector: rulerScreen.endValue, toVector: currentPosition)
                let lineNode = SCNNode(geometry: line)
                lineNode.geometry?.firstMaterial?.diffuse.contents = RulerLine.color
                rulerScreen.sceneView.scene.rootNode.addChildNode(lineNode)
                rulerScreen.currentCurveLine.curveLine.append(lineNode)
                
                let length = (rulerScreen.endValue.distance(from: currentPosition) * rulerScreen.unit.fator)
                
                rulerScreen.currentCurveLine.curveLength += length
                rulerScreen.setUpMessageLabel()
                rulerScreen.endValue = currentPosition
                glLineWidth(20)
            }
        } else {
            selectNearestCurvePoint()
        }
    }
    
    func getPointNode(position: SCNVector3) -> SCNNode {
        let startPointDot = SCNSphere(radius: 0.5)
        startPointDot.firstMaterial?.diffuse.contents = RulerLine.diselectedPointColor
        startPointDot.firstMaterial?.lightingModel = .constant
        startPointDot.firstMaterial?.isDoubleSided = true
        let node = SCNNode(geometry: startPointDot)
        node.scale = SCNVector3(1/500.0, 1/500.0, 1/500.0)
        node.position = position
        rulerScreen.sceneView.scene.rootNode.addChildNode(node)
        return node
    }
    
    func selectNearestCurvePoint() {
        
        guard let worldPosition = rulerScreen.sceneView.realWorldVector(screenPosition: rulerScreen.view.center) else { return }
        
        RulerLine.diselectNode(node: rulerScreen.startSelectedNode)
        rulerScreen.startSelectedNode = nil
        
        for (_, line) in rulerScreen.curveLines.enumerated() {
            
            if let startNode = line.startNode {
                let distanceToStartPoint = rulerScreen.rulerMeasurementsHelper.distanceBetweenPoints(firtsPoint: rulerScreen.sceneView.projectPoint(worldPosition), secondPoint: rulerScreen.sceneView.projectPoint(startNode.position))
                
                if distanceToStartPoint < 20  {
                    RulerLine.selectNode(node: startNode)
                    rulerScreen.startSelectedNode = line.startNode
                    rulerScreen.showMessageLabelForСurveLine(line: line)
                }
            }
            
            if let endNode = line.endNode {
                let distanceToStartPoint = rulerScreen.rulerMeasurementsHelper.distanceBetweenPoints(firtsPoint: rulerScreen.sceneView.projectPoint(worldPosition), secondPoint: rulerScreen.sceneView.projectPoint(endNode.position))
                
                if distanceToStartPoint < 20  {
                    RulerLine.selectNode(node: endNode)
                    rulerScreen.startSelectedNode = endNode
                    rulerScreen.showMessageLabelForСurveLine(line: line)
                }
            }
            
        }
        
    }
    
    func lineFrom(vector vector1: SCNVector3, toVector vector2: SCNVector3) -> SCNGeometry {
        
        let indices: [Int32] = [0, 1]
        
        let source = SCNGeometrySource(vertices: [vector1, vector2])
        let element = SCNGeometryElement(indices: indices, primitiveType: .line)
        
        return SCNGeometry(sources: [source], elements: [element])
    }
}
