//
//  SettingsController.swift
//  BeaverRuler
//
//  Created by Aleksandr Khotyashov on 8/22/17.
//  Copyright © 2017 Sasha. All rights reserved.
//

import UIKit

enum Setting: String {
    case measureUnits = "measureUnits"
}

class SettingsController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()

    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    // MARK: - Users Interactions

    @IBAction func loginFacebookPressed(_ sender: Any) {
        
    }

    @IBAction func measureUnitPressed(_ sender: Any) {

        let defaults = UserDefaults.standard

        let alertVC = UIAlertController(title: "Settings", message: "Please select distance unit options", preferredStyle: .actionSheet)
        alertVC.addAction(UIAlertAction(title: DistanceUnit.centimeter.title, style: .default) { [weak self] _ in
            defaults.set(DistanceUnit.centimeter.rawValue, forKey: Setting.measureUnits.rawValue)
        })
        alertVC.addAction(UIAlertAction(title: DistanceUnit.inch.title, style: .default) { [weak self] _ in
            defaults.set(DistanceUnit.inch.rawValue, forKey: Setting.measureUnits.rawValue)
        })
        alertVC.addAction(UIAlertAction(title: DistanceUnit.meter.title, style: .default) { [weak self] _ in
            defaults.set(DistanceUnit.meter.rawValue, forKey: Setting.measureUnits.rawValue)
        })
        alertVC.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        present(alertVC, animated: true, completion: nil)

    }

    @IBAction func removeAdsPressed(_ sender: Any) {

    }

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
