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

    private var apdLoader : APDNativeAdLoader! = APDNativeAdLoader()
    private var apdAdQueue : APDNativeAdQueue = APDNativeAdQueue()
    fileprivate var apdNativeArray : [APDNativeAd]! = Array()
    var capacity : Int = 4
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

        apdLoader.delegate = self
        apdLoader.loadAd(with: type, capacity: capacity)

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
        return userObjects.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = (tableView.dequeueReusableCell(withIdentifier: "UserObjectViewCell", for: indexPath) as? UserObjectViewCell)!

//        let userObjectData = userObjects[indexPath.row]
//
//        if let name = userObjectData.name {
//            cell.objectName.text = name
//        }
//
//        let objectUnit = DistanceUnit(rawValue: userObjectData.sizeUnit!)
//        let conversionFator = unit.fator / (objectUnit?.fator)!
//        cell.objectSize.text = String(format: "%.2f%", userObjectData.size * conversionFator) + " " + unit.unit
//
//        if let imageName = userObjectData.image {
//            let nsDocumentDirectory = FileManager.SearchPathDirectory.documentDirectory
//            let nsUserDomainMask = FileManager.SearchPathDomainMask.userDomainMask
//            let paths = NSSearchPathForDirectoriesInDomains(nsDocumentDirectory, nsUserDomainMask, true)
//            if let dirPath = paths.first {
//                let imageURL = URL(fileURLWithPath: dirPath).appendingPathComponent(imageName)
//                cell.imageView?.clipsToBounds = true
//                cell.imageView?.image = UIImage(contentsOfFile: imageURL.path)
//            }
//        }

        if indexPath.row < apdNativeArray.count {
            let nativeAd = apdNativeArray[indexPath.row]
            nativeAd.attach(to: cell.objectName, viewController: self)
        }

        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: false)
        
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let editObjectVC = storyboard.instantiateViewController(withIdentifier: "EditObjectViewController") as! EditObjectViewController
        editObjectVC.selectedObjectIndex = indexPath.row
        editObjectVC.delegate = self
        editObjectVC.modalPresentationStyle = .overCurrentContext
        self.present(editObjectVC, animated: true, completion: nil)
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 220
    }
    
    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return true
    }
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        if (editingStyle == UITableViewCellEditingStyle.delete) {
            let userObject = userObjects[indexPath.row]
            
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

extension ObjectsFoldersViewController : APDNativeAdLoaderDelegate {

    func nativeAdLoader(_ loader: APDNativeAdLoader!, didLoad nativeAds: [APDNativeAd]!) {
        print("\n ****************** \n adLoader didLoadNativeAd... \n ************************* \n")
        //apdNativeArray = nativeAds
        //let _ = nativeAds.map {( $0.delegate = self )}
    }

    func nativeAdLoader(_ loader: APDNativeAdLoader!, didFailToLoadWithError error: Error!){
        print("\n ****************** \n adLoader failed!!! \n ************************* \n")
    }
}

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
