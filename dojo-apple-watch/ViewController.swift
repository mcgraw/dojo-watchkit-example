//
//  ViewController.swift
//  dojo-apple-watch
//
//  Created by David McGraw on 11/19/14.
//  Copyright (c) 2014 David McGraw. All rights reserved.
//

import UIKit

class ViewController: UIViewController {

    @IBOutlet weak var equitySymbol: UILabel!
    @IBOutlet weak var equityFullName: UILabel!
    @IBOutlet weak var equityPrice: UILabel!
    @IBOutlet weak var equityTargetPrice: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.refreshInterface()
    }

    // MARK: Interface Updates
    
    // As it stands we only care about revealing the first target
    func refreshInterface() {
        var data: NSDictionary = XMCRequestDataForTopFourTargetsHit()
    
        if let key: String = data.allKeys.first as? String {
            let info: NSDictionary = data[key] as NSDictionary
            
            self.equitySymbol.text = key
            self.equityFullName.text = info["name"] as? String
            self.equityPrice.text = info["price"] as? String
            self.equityTargetPrice.text = info["target"] as? String
        }
    }
}

