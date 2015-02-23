//
//  AppDelegate.swift
//  dojo-apple-watch
//
//  Created by David McGraw on 11/19/14.
//  Copyright (c) 2014 David McGraw. All rights reserved.
//

import UIKit

let kClientId = "0a72523a8ac8430f91ca5006ea8d4e95"
let kCallbackURL = "spotifywatchexample://"
let kTokenSwapUrl = "http://localhost:1234/swap"
let kTokenRefreshUrl = "http://localhost:1234/refresh"

let kSessionWasUpdated = "kSessionWasUpdated"
let kSessionLoginDidSucceed = "kSessionLoginDidSucceed"
let kSessionLoginDidFail = "kSessionLoginDidFail"
let kSessionObjectDefaultsKey = "kSessionObjectDefaultsKey"

let kPlayerPlaySampleTrack = true

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?
    
    var session: SPTSession?
    var player: SPTAudioStreamingController?

    func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool {
        return true
    }
    
    func application(application: UIApplication, openURL url: NSURL, sourceApplication: String?, annotation: AnyObject?) -> Bool {
        if SPTAuth.defaultInstance().canHandleURL(url, withDeclaredRedirectURL: NSURL(string: kCallbackURL)) {
            SPTAuth.defaultInstance().handleAuthCallbackWithTriggeredAuthURL(url, tokenSwapServiceEndpointAtURL: NSURL(string: kTokenSwapUrl), callback: { (error, session) in
                if error != nil {
                    println("Authorization Error: \(error.localizedDescription)")
                } else {
                    // Store our session away for future usage
                    let sessionData = NSKeyedArchiver.archivedDataWithRootObject(session)
                    NSUserDefaults.standardUserDefaults().setObject(sessionData, forKey: kSessionObjectDefaultsKey)
                    NSUserDefaults.standardUserDefaults().synchronize()
                    
                    // Update our shared player
                    XMCSpotifyPlayer.sharedPlayer.session = session
        
                    // Notifiy our main interface
                    NSNotificationCenter.defaultCenter().postNotificationName(kSessionWasUpdated, object: session)
                }
            })
        }
        return false
    }
    

    func applicationWillResignActive(application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
    }

    func applicationDidEnterBackground(application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    }

    func applicationWillEnterForeground(application: UIApplication) {
        // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
    }

    func applicationDidBecomeActive(application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    }

    func applicationWillTerminate(application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    }
    
    func application(application: UIApplication, didReceiveLocalNotification notification: UILocalNotification) {
        NSLog("Received Local Notification")
    }
    
    func application(application: UIApplication, handleActionWithIdentifier identifier: String?, forLocalNotification notification: UILocalNotification, completionHandler: () -> Void) {
        NSLog("Process Local Notification Action")
        completionHandler()
    }
    
    func application(application: UIApplication, handleActionWithIdentifier identifier: String?, forRemoteNotification userInfo: [NSObject : AnyObject], completionHandler: () -> Void) {
        NSLog("Process Remote Notification Action")
        completionHandler()
    }
    
    // MARK: - Extension Request
    func application(application: UIApplication!, handleWatchKitExtensionRequest userInfo: [NSObject : AnyObject]!, reply: (([NSObject : AnyObject]!) -> Void)!) {
        let trigger = userInfo["trigger"] as String
        if trigger == "auth" {
            let value = XMCSpotifyPlayer.sharedPlayer.isAuthenticated()
            if value == false {
                reply(["value": "false"])
            } else {
                reply(["value": "true"])
            }
        }
        else if trigger == "login" {
            XMCSpotifyPlayer.sharedPlayer.loginSession(playbackDelegate: nil, delegate: nil, completed: { (success) in
                reply(["value": (success) ? "true" : "false"])
            })
        }
        else if trigger == "queue" {
            XMCSpotifyPlayer.sharedPlayer.queueDefaultAlbum({ (success) -> Void in
                reply(["value": (success) ? "true" : "false"])
            })
        }
        else if trigger == "play" {
            // pass control so we can fetch track metadata
            XMCSpotifyPlayer.sharedPlayer.playPlayerQueue()
            reply(nil)
        }
        else if trigger == "stop" {
            XMCSpotifyPlayer.sharedPlayer.stopPlayer()
            reply(nil)
        }
        else if trigger == "previous" {
            XMCSpotifyPlayer.sharedPlayer.skipPrevious()
            reply(nil)
        }
        else if trigger == "next" {
            XMCSpotifyPlayer.sharedPlayer.skipNext()
            reply(nil)
        }
        else if trigger == "image" {
            if XMCSpotifyPlayer.sharedPlayer.isPlaying() {
                XMCSpotifyPlayer.sharedPlayer.getAlbumArtAsDataForCurrentTrack({ (data) in
                    if let dict = data {
                        reply(["imageData": data!])
                    } else {
                        reply(nil)
                    }
                })
            } else {
                reply(["error": "not playing"])
            }
        }
        else if trigger == "metadata" {
            if XMCSpotifyPlayer.sharedPlayer.isPlaying() {
                let metadata = XMCSpotifyPlayer.sharedPlayer.player?.currentTrackMetadata as? [String: AnyObject]
                let duration = metadata?[SPTAudioStreamingMetadataTrackDuration] as NSTimeInterval
                let trackTitle = metadata?[SPTAudioStreamingMetadataTrackName] as String
                reply(["title": trackTitle, "duration": duration])
            } else {
                reply(["error": "not playing"])
            }
        }
        else {
            println("Unhandled trigger!")
            reply(nil)
        }
    }
}

