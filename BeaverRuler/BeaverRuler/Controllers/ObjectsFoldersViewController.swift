//
//  ObjectsFoldersViewController.swift
//  BeaverRuler
//
//  Created by Aleksandr Khotyashov on 8/23/17.
//  Copyright © 2017 Sasha. All rights reserved.
//

import UIKit
import Appodeal
import Crashlytics

class ObjectsFoldersViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, EditObjectVCDelegate {

    @IBOutlet weak var tableView: UITableView!

    private var apdAdQueue : APDNativeAdQueue = APDNativeAdQueue()
    fileprivate var apdNativeArray : [APDNativeAd]! = Array()
    var capacity : Int = 7
    let adDivisor = 3
    var type : APDNativeAdType = .auto
    var blockAd = false

    fileprivate var userObjects = GRDatabaseManager.sharedDatabaseManager.grRealm.objects(UserObjectRm.self).sorted(byKeyPath: "createdAt", ascending: false)
    fileprivate var unit: DistanceUnit = .centimeter

    override func viewDidLoad() {
        super.viewDidLoad()

        let defaults = UserDefaults.standard
        
        if let measureString = defaults.string(forKey: Setting.measureUnits.rawValue) {
            self.unit = DistanceUnit(rawValue: measureString)!
        }
        
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(UINib(nibName: "UserObjectViewCell", bundle: nil),  forCellReuseIdentifier:"UserObjectViewCell")
        tableView.register(UINib(nibName: "NativeAppInstallAdCell", bundle: nil),
                           forCellReuseIdentifier: "NativeAppInstallAdCell")

        if RageProducts.store.isProductPurchased(SettingsController.removeAdProductId) {
            blockAd = true
        }
        
        if blockAd == false {
            apdAdQueue.delegate = self
            apdAdQueue.setMaxAdSize(capacity)
            apdAdQueue.loadAd(of: type)
        }
        
        Answers.logCustomEvent(withName: "User gallery Screen")
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }

    // MARK: - UITableViewDataSource
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if blockAd == false {
            return userObjects.count + (userObjects.count / adDivisor)
        } else {
            return userObjects.count
        }
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {

        var cell = UITableViewCell()
        
        if (indexPath.row % adDivisor) == 0 && indexPath.row != 0 && blockAd == false {
            cell = showAds(indexPath: indexPath)
        } else {
            cell = showUserObject(indexPath: indexPath)
        }
        
        return cell
    }
    
    func showAds(indexPath: IndexPath) -> UITableViewCell {
        let nativeAppInstallAdCell = (tableView.dequeueReusableCell(
            withIdentifier: "NativeAppInstallAdCell", for: indexPath) as? NativeAppInstallAdCell)!
        
        if apdNativeArray.count > 0 {
            
            if nativeAppInstallAdCell.nativeAd != nil {
                nativeAppInstallAdCell.nativeAd.detachFromView()
            }
            
            let adIndex = arc4random_uniform(UInt32(apdNativeArray.count))
            
            let nativeAd = apdNativeArray[Int(adIndex)]
            
            nativeAd.attach(to: nativeAppInstallAdCell.contentView, viewController: self)
            nativeAppInstallAdCell.mediaView.setNativeAd(nativeAd, rootViewController: self)
            
            nativeAppInstallAdCell.titleLabel.text = nativeAd.title;
            nativeAppInstallAdCell.descriptionLabel.text = nativeAd.descriptionText;
            nativeAppInstallAdCell.callToActionLabel.text = nativeAd.callToActionText;
            
            if let adChoices = nativeAd.adChoicesView {
                adChoices.frame = CGRect.init(x: 0, y: 0, width: 24, height: 24)
                nativeAppInstallAdCell.contentView.addSubview(adChoices)
            }
        }
        
        return nativeAppInstallAdCell
    }
    
    func showUserObject(indexPath: IndexPath) -> UITableViewCell {
        let cell = (tableView.dequeueReusableCell(withIdentifier: "UserObjectViewCell", for: indexPath) as? UserObjectViewCell)!
        
        if blockAd == false {
            cell.objectIndex = indexPath.row - (indexPath.row / adDivisor)
            
        } else {
            cell.objectIndex = indexPath.row
        }
        
        let userObjectData = userObjects[cell.objectIndex]
        
        if let name = userObjectData.name {
            cell.objectName.text = name
        }
        
        let objectUnit = DistanceUnit(rawValue: userObjectData.sizeUnit!)
        let conversionFator = unit.fator / (objectUnit?.fator)!
        cell.objectSize.text = String(format: "%.2f%", userObjectData.size * conversionFator) + " " + unit.unit
        
        if let imageName = userObjectData.image {
            let nsDocumentDirectory = FileManager.SearchPathDirectory.documentDirectory
            let nsUserDomainMask = FileManager.SearchPathDomainMask.userDomainMask
            let paths = NSSearchPathForDirectoriesInDomains(nsDocumentDirectory, nsUserDomainMask, true)
            if let dirPath = paths.first {
                let imageURL = URL(fileURLWithPath: dirPath).appendingPathComponent(imageName)
                cell.imageView?.clipsToBounds = true
                cell.imageView?.image = UIImage(contentsOfFile: imageURL.path)
            }
        }
        
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: false)
        
        if let cell = tableView.cellForRow(at: indexPath) as? UserObjectViewCell {
            let storyboard = UIStoryboard(name: "Main", bundle: nil)
            let editObjectVC = storyboard.instantiateViewController(withIdentifier: "EditObjectViewController") as! EditObjectViewController
            editObjectVC.selectedObjectIndex = cell.objectIndex
            editObjectVC.delegate = self
            editObjectVC.modalPresentationStyle = .overCurrentContext
            Answers.logCustomEvent(withName: "User select object: \(cell.objectIndex)")
            self.present(editObjectVC, animated: true, completion: nil)
        }
        
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 220
    }
    
    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return true
    }
    
    // MARK: - EditObjectVCDelegate
    func reloadObjects() {
        tableView.reloadData()
    }

}

// MARK: - NativeAd

extension ObjectsFoldersViewController : APDNativeAdPresentationDelegate {

    func nativeAdWillLogImpression(_ nativeAd: APDNativeAd!) {
        print("\n ****************** \n nativeAdWillLogUserInteraction nativeAdWillLogImpression at index ", apdNativeArray.index(of: nativeAd)!, "\n ************************* \n")
    }

    func nativeAdWillLogUserInteraction(_ nativeAd: APDNativeAd!) {
        Answers.logCustomEvent(withName: "User click on ad")
        print("\n ****************** \n nativeAdWillLogUserInteraction ", apdNativeArray.index(of: nativeAd)!, "\n ************************* \n")
    }
}

extension ObjectsFoldersViewController : APDNativeAdQueueDelegate {

    func adQueue(_ adQueue: APDNativeAdQueue!, failedWithError error: Error!) {
        print("\n ****************** \n adQueue failed!!!... \n ************************* \n")
    }

    func adQueueAdIsAvailable(_ adQueue: APDNativeAdQueue!, ofCount count: Int) {
        apdNativeArray.append(contentsOf:adQueue.getNativeAds(ofCount: count))
        let _ = apdNativeArray.map {( $0.delegate = self )}
        print("\n ****************** \n adQueue is available now... \n ************************* \n")

        if apdNativeArray.count > 0 {

        } else {
            apdNativeArray.append(contentsOf:adQueue.getNativeAds(ofCount: 1))
            let _ = apdNativeArray.map {( $0.delegate = self )}
        }
    }

}
