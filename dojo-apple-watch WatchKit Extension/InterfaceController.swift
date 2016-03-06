//
//  InterfaceController.swift
//  dojo-apple-watch WatchKit Extension
//
//  Created by David McGraw on 11/19/14.
//  Copyright (c) 2014 David McGraw. All rights reserved.
//

import WatchKit
import WatchConnectivity
import Foundation

enum PlayState {
    case Paused, Playing
}

class InterfaceController: WKInterfaceController {
    
    @IBOutlet weak var authGroup: WKInterfaceGroup!
    @IBOutlet weak var playerGroup: WKInterfaceGroup!
    @IBOutlet weak var playerControlsGroup: WKInterfaceGroup!
    
    @IBOutlet weak var welcomeTitle: WKInterfaceLabel!
    @IBOutlet weak var trackName: WKInterfaceLabel!
    @IBOutlet weak var trackTime: WKInterfaceTimer!
    
    @IBOutlet weak var prevTrack: WKInterfaceButton!
    @IBOutlet weak var playToggle: WKInterfaceButton!
    @IBOutlet weak var nextTrack: WKInterfaceButton!
    
    var state: PlayState = .Paused
    
    override func awakeWithContext(context: AnyObject?) {
        super.awakeWithContext(context)
        
        // Are we authenticated?
        print("Check Authentication")
        WCSession.defaultSession().sendMessage(["trigger" :"auth"], replyHandler: { (replyInfo) in
            if let value = replyInfo["value"] as? String {
                if value == "true" {
                    self.performLogin()
                } else {
                    self.authGroup.setHidden(false)
                    self.playerGroup.setHidden(true)
                }
            }
        }) { (error) in
            print("Error: \(error)")
        }
    }
    
    func performLogin() {
        print("Perform Login")
        WCSession.defaultSession().sendMessage(["trigger": "login"], replyHandler: { (replyInfo) -> Void in
            if let value = replyInfo["value"] as? String where value == "true" {
                self.performAlbumQueue()
            }
        }) { (error) in
            print("Error: \(error)")
        }
    }
    
    func performAlbumQueue() {
        print("Add album to queue")
        WCSession.defaultSession().sendMessage(["trigger": "queue"], replyHandler: { (replyInfo) -> Void in
            if let value = replyInfo["value"] as? String {
                if value == "false" {
                    self.playToggle.setEnabled(false)
                    self.authGroup.setHidden(false)
                    self.playerGroup.setHidden(true)
                } else {
                    print("Did login")
                    self.playToggle.setEnabled(true)
                }
            }
        }) { (error) in
            print("Error: \(error)")
        }
    }
    
    func getMetadata() {
        print("Fetch Metadata")
        WCSession.defaultSession().sendMessage(["trigger": "metadata"], replyHandler: { (replyInfo) -> Void in
            if let _ = replyInfo["error"] as? String {
                self.playerDidError()
            } else {
                let trackTitle = replyInfo["title"] as! String
                let duration = replyInfo["duration"] as! Double
                
                self.trackName.setText(trackTitle)
                self.trackTime.setDate(NSDate(timeIntervalSinceNow: duration))
                self.trackTime.start()
                self.trackTime.setHidden(false)
                self.trackName.setHidden(false)
                self.welcomeTitle.setHidden(true)
            }
        }) { (error) in
            print("Error: \(error)")
        }
    }
    
    func getImage() {
        print("Fetch Album Image")
        WCSession.defaultSession().sendMessage(["trigger": "image"], replyHandler: { (replyInfo) -> Void in
            if let _ = replyInfo["error"] as? String {
                self.playerDidError()
            } else {
                if let data = replyInfo["imageData"] as? NSData {
                    self.playerGroup.setBackgroundImageData(data)
                }
            }
        }) { (error) in
            print("Error: \(error)")
        }
    }
    
    // MARK: - Actions
    
    @IBAction func previousActionPressed() {
        WCSession.defaultSession().sendMessage(["trigger": "previous"], replyHandler: { (replyInfo) -> Void in
            // track should have moved
            NSTimer.scheduledTimerWithTimeInterval(0.5, target: self, selector: "refreshMetadata", userInfo: nil, repeats: false)
        }) { (error) in
            print("Error: \(error)")
        }
    }
    
    @IBAction func nextActionPressed() {
        WCSession.defaultSession().sendMessage(["trigger": "next"], replyHandler: { (replyInfo) -> Void in
            NSTimer.scheduledTimerWithTimeInterval(0.5, target: self, selector: "refreshMetadata", userInfo: nil, repeats: false)
        }) { (error) in
                print("Error: \(error)")
        }
    }
    
    @IBAction func playActionPressed() {
        if state == .Paused {
            state = .Playing
            self.prevTrack.setEnabled(true)
            self.nextTrack.setEnabled(true)
            playToggle.setBackgroundImageNamed("watch-pause")
            
            WCSession.defaultSession().sendMessage(["trigger": "play"], replyHandler: { (replyInfo) -> Void in
                NSTimer.scheduledTimerWithTimeInterval(0.5, target: self, selector: "refreshMetadata", userInfo: nil, repeats: false)
            }) { (error) in
                print("Error: \(error)")
            }
        } else {
            state = .Paused
            self.prevTrack.setEnabled(false)
            self.nextTrack.setEnabled(false)
            playToggle.setBackgroundImageNamed("watch-play")
            
            WCSession.defaultSession().sendMessage(["trigger": "stop"], replyHandler: { (replyInfo) -> Void in
                self.trackTime.stop()
            }) { (error) in
                print("Error: \(error)")
            }
        }
    }
    
    func refreshMetadata() {
        getMetadata()
        getImage()
    }
    
    func playerDidError() {
        welcomeTitle.setText("Bugs are fun... try again!")
        welcomeTitle.setHidden(false)
        trackName.setText("")
        trackTime.stop()
        trackTime.setHidden(true)
        trackName.setHidden(true)
        prevTrack.setEnabled(false)
        nextTrack.setEnabled(false)
        playToggle.setBackgroundImageNamed("watch-play")
    }
}
