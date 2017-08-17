//
//  ARSCNView.swift
//  Measure
//
//  Created by levantAJ on 8/9/17.
//  Copyright © 2017 levantAJ. All rights reserved.
//

import SceneKit
import ARKit

extension ARSCNView {

        func realWorldVector(position: CGPoint) -> (position: SCNVector3?, planeAnchor: ARPlaneAnchor?, hitAPlane: Bool) {

            // -------------------------------------------------------------------------------
            // 1. Always do a hit test against exisiting plane anchors first.
            //    (If any such anchors exist & only within their extents.)

            let planeHitTestResults = self.hitTest(position, types: .existingPlaneUsingExtent)
            if let result = planeHitTestResults.first {

                let planeHitTestPosition = SCNVector3.positionFromTransformMatrix(result.worldTransform)
                let planeAnchor = result.anchor

                // Return immediately - this is the best possible outcome.
                return (planeHitTestPosition, planeAnchor as? ARPlaneAnchor, true)
            }

            // -------------------------------------------------------------------------------
            // 2. Collect more information about the environment by hit testing against
            //    the feature point cloud, but do not return the result yet.

            var featureHitTestPosition: SCNVector3?
            var highQualityFeatureHitTestResult = false

            let highQualityfeatureHitTestResults = self.hitTestWithFeatures(position, coneOpeningAngleInDegrees: 5, minDistance: 0.1, maxDistance: 3.0)

            // 过滤特征点
            let featureCloud = self.fliterWithFeatures(highQualityfeatureHitTestResults)

            if !featureCloud.isEmpty {
                featureHitTestPosition = featureCloud.average
                highQualityFeatureHitTestResult = true
            }else if !highQualityfeatureHitTestResults.isEmpty {
                featureHitTestPosition = highQualityfeatureHitTestResults.map { (featureHitTestResult) -> SCNVector3 in
                    return featureHitTestResult.position
                    }.average
                highQualityFeatureHitTestResult = true
            }

            // -------------------------------------------------------------------------------
            // 4. If available, return the result of the hit test against high quality
            //    features if the hit tests against infinite planes were skipped or no
            //    infinite plane was hit.

            if highQualityFeatureHitTestResult {
                return (featureHitTestPosition, nil, false)
            }

            // -------------------------------------------------------------------------------
            // 5. As a last resort, perform a second, unfiltered hit test against features.
            //    If there are no features in the scene, the result returned here will be nil.

            let unfilteredFeatureHitTestResults = self.hitTestWithFeatures(position)
            if !unfilteredFeatureHitTestResults.isEmpty {
                let result = unfilteredFeatureHitTestResults[0]
                return (result.position, nil, false)
            }

            return (nil, nil, false)

        }

    func planeLineIntersectPoint(planeVector: SCNVector3 , planePoint: SCNVector3, lineVector: SCNVector3, linePoint: SCNVector3) -> SCNVector3? {
        let vpt = planeVector.x*lineVector.x + planeVector.y*lineVector.y + planeVector.z*lineVector.z
        if vpt != 0 {
            let t = ((planePoint.x-linePoint.x)*planeVector.x + (planePoint.y-linePoint.y)*planeVector.y + (planePoint.z-linePoint.z)*planeVector.z)/vpt
            let cross = SCNVector3Make(linePoint.x + lineVector.x*t, linePoint.y + lineVector.y*t, linePoint.z + lineVector.z*t)
            if (cross-linePoint).length() < 5 {
                return cross
            }
        }
        return nil
    }

//    func realWorldVector(screenPosition: CGPoint) -> SCNVector3? {
//        let results = self.hitTest(screenPosition, types: [.featurePoint])
//        guard let result = results.first else { return nil }
//        return SCNVector3.positionFromTransform(result.worldTransform)
//    }
}
