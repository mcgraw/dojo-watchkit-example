//
//  InterfaceController.swift
//  dojo-apple-watch WatchKit Extension
//
//  Created by David McGraw on 11/19/14.
//  Copyright (c) 2014 David McGraw. All rights reserved.
//

import WatchKit
import Foundation


class InterfaceController: WKInterfaceController {
    
    @IBOutlet weak var position1: WKInterfaceLabel!
    @IBOutlet weak var position2: WKInterfaceLabel!
    @IBOutlet weak var position3: WKInterfaceLabel!
    @IBOutlet weak var position4: WKInterfaceLabel!

    override func awakeWithContext(context: AnyObject?) {
        super.awakeWithContext(context)
        
        clearData()
        
        loadData()
    }
    
    override func handleUserActivity(userInfo: [NSObject : AnyObject]!) {
        if let val: String = userInfo["identifier"] as? String {
            presentControllerWithName("targetsHit", context: nil)
        }
    }
    
    // MARK: Layout
    
    func loadData() {
        var data: NSDictionary = XMCRequestDataForAllTargets()
        var index = 0
        
        for key: AnyObject in data.allKeys {
            let str: String = key as String
            
            switch index {
            case 0:
                position1.setText(str)
            case 1:
                position2.setText(str)
                position2.setHidden(false)
            case 2:
                position3.setText(str)
                position3.setHidden(false)
            case 3:
                position4.setText(str)
                position4.setHidden(false)
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
        
        position2.setHidden(true)
        position3.setHidden(true)
        position4.setHidden(true)
    }
    
    override func handleActionWithIdentifier(identifier: String?, forLocalNotification localNotification: UILocalNotification) {
        NSLog("Handle Action For Local Notification")
    }
    
    override func handleActionWithIdentifier(identifier: String?, forRemoteNotification remoteNotification: [NSObject : AnyObject]) {
        NSLog("Handle Action For Remote Notification")
    }

}
