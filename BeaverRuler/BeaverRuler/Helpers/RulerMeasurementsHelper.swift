//
//  RulerMeasurementsHelper.swift
//  BeaverRuler
//
//  Created by user on 11/18/17.
//  Copyright © 2017 Sasha. All rights reserved.
//

import Foundation
import UIKit
import SceneKit

class RulerMeasurementsHelper {
    
    var rulerScreen: ViewController!
    
    func getEndValue(worldPosition: SCNVector3) -> SCNVector3 {
        
        var position = worldPosition
        
        if rulerScreen.lines.count > 0 {
            let centerTargerVectorInWorld = rulerScreen.sceneView.projectPoint(worldPosition)
            for line in rulerScreen.lines {
                
                if rulerScreen.endSelectedNode == nil {
                    if let endPoint = line.endVector {
                        let distance = distanceBetweenPoints(firtsPoint: centerTargerVectorInWorld, secondPoint: rulerScreen.sceneView.projectPoint(endPoint))
                        if distance < 9 {
                            position = endPoint
                            break
                        }
                    }
                } else {
                    if rulerScreen.endSelectedNode != line.endNode  {
                        if let endPoint = line.endVector {
                            let distance = distanceBetweenPoints(firtsPoint: centerTargerVectorInWorld, secondPoint: rulerScreen.sceneView.projectPoint(endPoint))
                            if distance < 9 {
                                position = endPoint
                                break
                            }
                        }
                    }
                }
                
                if rulerScreen.startSelectedNode == nil {
                    if let startPoint = line.startVector {
                        let distance = distanceBetweenPoints(firtsPoint: centerTargerVectorInWorld, secondPoint: rulerScreen.sceneView.projectPoint(startPoint))
                        if distance < 9 {
                            position = startPoint
                            break
                        }
                    }
                } else {
                    if rulerScreen.startSelectedNode != line.startNode  {
                        if let startPoint = line.startVector {
                            let distance = distanceBetweenPoints(firtsPoint: centerTargerVectorInWorld, secondPoint: rulerScreen.sceneView.projectPoint(startPoint))
                            if distance < 9 {
                                position = startPoint
                                break
                            }
                        }
                    }
                }
                
            }
        }
        
        return position
    }
    
    func distanceBetweenPoints(firtsPoint:SCNVector3, secondPoint:SCNVector3) -> Float{
        let xd = firtsPoint.x - secondPoint.x
        let yd = firtsPoint.y - secondPoint.y
        let zd = firtsPoint.z - secondPoint.z
        let distance = Float(sqrt(xd * xd + yd * yd + zd * zd))
        
        if (distance < 0){
            return (distance * -1)
        } else {
            return (distance)
        }
    }
}
