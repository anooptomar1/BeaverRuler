//
//  UserObjectRm.swift
//  BeaverRuler
//
//  Created by Aleksandr Khotyashov on 8/23/17.
//  Copyright © 2017 Sasha. All rights reserved.
//

import RealmSwift

class UserObjectRm: Object {

    @objc dynamic var id: String?
    @objc dynamic var name: String?
    @objc dynamic var folderName: String?
    @objc dynamic var image: String?
    @objc dynamic var size: Float = 0.00
    @objc dynamic var sizeUnit: String?
    
    override class func primaryKey() -> String{
        return "id"
    }

}
