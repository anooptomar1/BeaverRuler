//
//  ObjectsFoldersViewController.swift
//  BeaverRuler
//
//  Created by Aleksandr Khotyashov on 8/23/17.
//  Copyright © 2017 Sasha. All rights reserved.
//

import UIKit

class ObjectsFoldersViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {

    @IBOutlet weak var tableView: UITableView!

    var userObjects = GRDatabaseManager.sharedDatabaseManager.grRealm.objects(UserObjectRm.self)

    override func viewDidLoad() {
        super.viewDidLoad()

        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(UINib(nibName: "UserObjectViewCell", bundle: nil),  forCellReuseIdentifier:"UserObjectViewCell")
        
        let userObjectRm1 = UserObjectRm()
        userObjectRm1.name = "1"
        userObjectRm1.id = "1"
        
        let userObjectRm2 = UserObjectRm()
        userObjectRm2.name = "2"
        userObjectRm2.id = "2"
        
        let userObjectRm3 = UserObjectRm()
        userObjectRm3.name = "3"
        userObjectRm3.id = "3"
        
        try! GRDatabaseManager.sharedDatabaseManager.grRealm.write({
            GRDatabaseManager.sharedDatabaseManager.grRealm.add(userObjectRm1, update:true)
            GRDatabaseManager.sharedDatabaseManager.grRealm.add(userObjectRm2, update:true)
            GRDatabaseManager.sharedDatabaseManager.grRealm.add(userObjectRm3, update:true)
        })
        
        userObjects = GRDatabaseManager.sharedDatabaseManager.grRealm.objects(UserObjectRm.self)
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

        let userObjectData = userObjects[indexPath.row]
        
        if let name = userObjectData.name {
            cell.objectName.text = name
        }
        
        cell.objectSize.text = String(userObjectData.size)
        
        if let imageName = userObjectData.image {
            let nsDocumentDirectory = FileManager.SearchPathDirectory.documentDirectory
            let nsUserDomainMask = FileManager.SearchPathDomainMask.userDomainMask
            let paths = NSSearchPathForDirectoriesInDomains(nsDocumentDirectory, nsUserDomainMask, true)
            if let dirPath = paths.first {
                let imageURL = URL(fileURLWithPath: dirPath).appendingPathComponent(imageName)
                cell.imageView?.image = UIImage(contentsOfFile: imageURL.path)
            }
        }
        
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: false)
        
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 220
    }

}
