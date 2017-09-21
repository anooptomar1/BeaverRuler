//
//  AppAnalyticsHelper.swift
//  BeaverRuler
//
//  Created by Aleksandr Khotyashov on 9/21/17.
//  Copyright © 2017 Sasha. All rights reserved.
//

import Foundation
import Crashlytics
import FacebookCore

class AppAnalyticsHelper {

    static func sendAppAnalyticEvent(withName: String) {
        Answers.logCustomEvent(withName: withName)
        AppEventsLogger.log(withName)
    }

}
