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

    var userObjects = GRDatabaseManager.sharedDatabaseManager.grRealm.objects(UserAddressRm.self)

    override func viewDidLoad() {
        super.viewDidLoad()

        tableView.register(UINib(nibName: "UserObjectViewCell", bundle: nil),  forCellReuseIdentifier:"UserObjectViewCell")
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }

    // MARK: - UITableViewDataSource
    func numberOfSections(in tableView: UITableView) -> Int {
        return 0
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return userObjects.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = (tableView.dequeueReusableCell(withIdentifier: "UserObjectViewCell", for: indexPath) as? UserObjectViewCell)!

        let userObjectData = userObjects[indexPath.row]
        cell.objectName.text = userObjectData.name
        cell.objectSize.text = String(userObjectData.size)

        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: false)
        
    }

}
