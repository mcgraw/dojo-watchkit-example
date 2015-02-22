//
//  GlanceController.swift
//  dojo-apple-watch WatchKit Extension
//
//  Created by David McGraw on 11/19/14.
//  Copyright (c) 2014 David McGraw. All rights reserved.
//

import WatchKit
import Foundation

class GlanceController: WKInterfaceController {
    
    override func awakeWithContext(context: AnyObject?) {
        super.awakeWithContext(context)
    }

    override func willActivate() {
        super.willActivate()
        
        // If this glance is touched, this will notify our main interface that a different
        // view should be shown
        self.updateUserActivity("glance", userInfo: ["identifier": "targetsHit"], webpageURL: nil)
    }
}
