//
//  UserObjectRm.swift
//  BeaverRuler
//
//  Created by Aleksandr Khotyashov on 8/23/17.
//  Copyright © 2017 Sasha. All rights reserved.
//

import RealmSwift

class UserAddressRm: Object {

    @objc dynamic var name: String?
    @objc dynamic var folderName: String?
    @objc dynamic var image: String?
    @objc dynamic var size = 0
    @objc dynamic var sizeUnit: String?

}
