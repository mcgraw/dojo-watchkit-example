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

    @IBOutlet weak var position1: WKInterfaceLabel!
    @IBOutlet weak var position2: WKInterfaceLabel!
    @IBOutlet weak var position3: WKInterfaceLabel!
    @IBOutlet weak var position4: WKInterfaceLabel!
    
    override init(context: AnyObject?) {
        super.init(context: context)
        
        clearData()
        
        loadData()
    }

    override func willActivate() {
        super.willActivate()
        
        // If this glance is touched, this will notify our main interface that a different
        // view should be shown
        self.updateUserActivity("glance", userInfo: ["identifier": "targetsHit"])
    }

    // MARK: Data Handling
    
    func loadData() {
        var data: NSDictionary = XMCRequestDataForTopFourTargetsHit()
        var index = 0
        
        for key: AnyObject in data.allKeys {
            let str: String = key as String
            
            switch index {
            case 0:
                position1.setText(str)
            case 1:
                position2.setText(str)
            case 2:
                position3.setText(str)
            case 3:
                position4.setText(str)
            default:
                continue
            }
            index++
        }
    }
    
    func clearData() {
        position1.setText("NONE")
        position2.setText("")
        position3.setText("")
        position4.setText("")
    }
}
