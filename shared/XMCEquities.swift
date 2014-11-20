//
//  XMCEquities.swift
//  dojo-apple-watch
//
//  Created by David McGraw on 11/19/14.
//  Copyright (c) 2014 David McGraw. All rights reserved.
//

import Foundation

func XMCRequestDataForTopFourTargetsHit() -> NSDictionary {
    return [ "AAPL": [ "name": "Apple, Inc.", "price": "119.44", "target": "120.00"] ]
}

func XMCRequestDataForAllTargets() -> NSDictionary {
    return [ "AAPL": [ "name": "Apple, Inc.", "price": "124.44", "target": "120.00"],
             "TSLA": [ "name": "Tesla Motors", "price": "247.32", "target": "225.00"],
             "HAL": [ "name": "Halliburton", "price": "48.09", "target": "42.00"],
             "W": [ "name": "Wayfair, Inc.", "price": "22.02", "target": "20.00"] ]
}