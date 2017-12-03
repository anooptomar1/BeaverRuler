//
//  RulerModeViewController.swift
//  BeaverRuler
//
//  Created by user on 12/3/17.
//  Copyright © 2017 Sasha. All rights reserved.
//

import UIKit

protocol RulerModeVCDelegate {
    func selectMode(type: RulerType)
}

class RulerModeViewController: UIViewController {
    
    @IBOutlet weak var standardRulerNormalButton: UIButton!
    @IBOutlet weak var standardRulerSelectedButton: UIButton!
    @IBOutlet weak var curveRulerNormalButton: UIButton!
    @IBOutlet weak var curveRulerSelectedButton: UIButton!
    @IBOutlet weak var pointRulerNormalButton: UIButton!
    @IBOutlet weak var pointRulerSelectedButton: UIButton!
    
    var selectedRulerType: RulerType!
    var delegate: RulerModeVCDelegate?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        switch selectedRulerType {
        case .UsualRuler:
            selectStandardRuler()
        case .СurveRuler:
            selectCurveRuler()
        case .PointRuler:
            selectPointRuler()
        default:
            break
        }
        
        // Do any additional setup after loading the view.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func standardRulerSelected(_ sender: Any) {
        AppAnalyticsHelper.sendAppAnalyticEvent(withName: "Select_standard_ruler_pressed")
        selectStandardRuler()
        
        if let delegate = delegate {
            delegate.selectMode(type: selectedRulerType)
        }
        
        dismiss(animated: true, completion: nil)
    }
    
    func selectStandardRuler() {
        selectedRulerType = RulerType.UsualRuler
        standardRulerNormalButton.isHidden = true
        standardRulerSelectedButton.isHidden = false
        curveRulerNormalButton.isHidden = false
        curveRulerSelectedButton.isHidden = true
        pointRulerNormalButton.isHidden = false
        pointRulerSelectedButton.isHidden = true
    }
    
    @IBAction func curveRulerSelected(_ sender: Any) {
        AppAnalyticsHelper.sendAppAnalyticEvent(withName: "Select_curve_ruler_pressed")
        selectCurveRuler()
        
        if let delegate = delegate {
            delegate.selectMode(type: selectedRulerType)
        }
        
        dismiss(animated: true, completion: nil)
    }
    
    func selectCurveRuler() {
        selectedRulerType = RulerType.СurveRuler
        standardRulerNormalButton.isHidden = false
        standardRulerSelectedButton.isHidden = true
        curveRulerNormalButton.isHidden = true
        curveRulerSelectedButton.isHidden = false
        pointRulerNormalButton.isHidden = false
        pointRulerSelectedButton.isHidden = true
    }
    
    @IBAction func pointRulerSelected(_ sender: Any) {
        AppAnalyticsHelper.sendAppAnalyticEvent(withName: "Select_point_ruler_pressed")
        selectPointRuler()
        
        if let delegate = delegate {
            delegate.selectMode(type: selectedRulerType)
        }
        
        dismiss(animated: true, completion: nil)
    }
    
    func selectPointRuler() {
        selectedRulerType = RulerType.PointRuler
        standardRulerNormalButton.isHidden = false
        standardRulerSelectedButton.isHidden = true
        curveRulerNormalButton.isHidden = false
        curveRulerSelectedButton.isHidden = true
        pointRulerNormalButton.isHidden = true
        pointRulerSelectedButton.isHidden = false
    }
    
    
}
