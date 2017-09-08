//
//  ObjectsFoldersViewController.swift
//  BeaverRuler
//
//  Created by Aleksandr Khotyashov on 8/23/17.
//  Copyright © 2017 Sasha. All rights reserved.
//

import UIKit
import Appodeal

class ObjectsFoldersViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, EditObjectVCDelegate {
    
    @IBOutlet weak var tableView: UITableView!

    private var apdAdQueue : APDNativeAdQueue = APDNativeAdQueue()
    fileprivate var apdNativeArray : [APDNativeAd]! = Array()
    var capacity : Int = 4
    let adDivisor = 3
    var type : APDNativeAdType = .auto
    var isAdQueue = true

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

        guard !isAdQueue else {
            apdAdQueue.delegate = self
            apdAdQueue.setMaxAdSize(capacity)
            apdAdQueue.loadAd(of: type)
            return
        }
        
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }

    // MARK: - UITableViewDataSource
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return userObjects.count + (userObjects.count / adDivisor)
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {

        var cell = UITableViewCell()
        
        if (indexPath.row % adDivisor) == 0 && indexPath.row != 0 {
            cell = showAds(indexPath: indexPath)
        } else {
            cell = showUserObject(indexPath: indexPath)
        }
        
        return cell
    }
    
    func showAds(indexPath: IndexPath) -> UITableViewCell {
        let nativeAppInstallAdCell = (tableView.dequeueReusableCell(
            withIdentifier: "NativeAppInstallAdCell", for: indexPath) as? NativeAppInstallAdCell)!
        
        if indexPath.row < apdNativeArray.count {
            
            if nativeAppInstallAdCell.nativeAd != nil {
                nativeAppInstallAdCell.nativeAd.detachFromView()
            }
            
            let nativeAd = apdNativeArray[indexPath.row]
            
            nativeAd.attach(to: nativeAppInstallAdCell.contentView, viewController: self)
            nativeAppInstallAdCell.mediaView.setNativeAd(nativeAd, rootViewController: self)
            
            nativeAppInstallAdCell.titleLabel.text = nativeAd.title;
            nativeAppInstallAdCell.descriptionLabel.text = nativeAd.descriptionText;
            nativeAppInstallAdCell.callToActionLabel.text = nativeAd.callToActionText;
        }
        
        return nativeAppInstallAdCell
    }
    
    func showUserObject(indexPath: IndexPath) -> UITableViewCell {
        let cell = (tableView.dequeueReusableCell(withIdentifier: "UserObjectViewCell", for: indexPath) as? UserObjectViewCell)!
        
        cell.objectIndex = indexPath.row - (indexPath.row / adDivisor)
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
            self.present(editObjectVC, animated: true, completion: nil)
        }
        
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 220
    }
    
    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return true
    }
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        if (editingStyle == UITableViewCellEditingStyle.delete) {
            let objectIndex = indexPath.row - (indexPath.row / adDivisor)
            let userObject = userObjects[objectIndex]
            
            try! GRDatabaseManager.sharedDatabaseManager.grRealm.write {
                GRDatabaseManager.sharedDatabaseManager.grRealm.delete(userObject)
            }
            
            userObjects = GRDatabaseManager.sharedDatabaseManager.grRealm.objects(UserObjectRm.self).sorted(byKeyPath: "createdAt", ascending: false)
            
            tableView.deleteRows(at: [indexPath], with: .fade)
        }
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
