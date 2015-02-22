//
//  InterfaceController.swift
//  dojo-apple-watch WatchKit Extension
//
//  Created by David McGraw on 11/19/14.
//  Copyright (c) 2014 David McGraw. All rights reserved.
//

import WatchKit
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
        println("Check Authentication")
        WKInterfaceController.openParentApplication(["trigger" :"auth"], reply: { (replyInfo, error) in
            if let value = replyInfo["value"] as? String {
                if value == "true" {
                    self.performLogin()
                } else {
                    self.authGroup.setHidden(false)
                    self.playerGroup.setHidden(true)
                }
            }
        })
    }
    
    func performLogin() {
        println("Perform Login")
        WKInterfaceController.openParentApplication(["trigger": "login"], reply: { (replyInfo, error) in
            if error != nil {
                println("Error: \(error.localizedDescription)")
            } else {
                let value = replyInfo["value"] as String
                if value == "true" {
                    self.performAlbumQueue()
                }
            }
        })
    }
    
    func performAlbumQueue() {
        println("Add album to queue")
        WKInterfaceController.openParentApplication(["trigger": "queue"], reply: { (replyInfo, error) in
            if error != nil {
                println("Error: \(error.localizedDescription)")
            } else {
                if let value = replyInfo["value"] as? String {
                    if value == "false" {
                        self.playToggle.setEnabled(false)
                        self.authGroup.setHidden(false)
                        self.playerGroup.setHidden(true)
                    } else {
                        println("Did login")
                        self.playToggle.setEnabled(true)
                    }
                }
            }
        })
    }
    
    func getMetadata() {
        println("Fetch Metadata")
        WKInterfaceController.openParentApplication(["trigger": "metadata"], reply: { (replyInfo, error) in
            if error != nil {
                println("Error: \(error.localizedDescription)")
            } else {
                if let infoError = replyInfo["error"] as? String {
                    self.playerDidError()
                } else {
                    let trackTitle = replyInfo["title"] as String
                    let duration = replyInfo["duration"] as Double
                    
                    self.trackName.setText(trackTitle)
                    self.trackTime.setDate(NSDate(timeIntervalSinceNow: duration))
                    self.trackTime.start()
                    self.trackTime.setHidden(false)
                    self.trackName.setHidden(false)
                    self.welcomeTitle.setHidden(true)
                }
            }
        })
    }
    
    func getImage() {
        println("Fetch Album Image")
        WKInterfaceController.openParentApplication(["trigger": "image"], reply: { (replyInfo, error) in
            if error != nil {
                println("Error: \(error.localizedDescription)")
            } else {
                if let infoError = replyInfo["error"] as? String {
                    self.playerDidError()
                } else {
                    if let data = replyInfo["imageData"] as? NSData {
                        self.playerGroup.setBackgroundImageData(data)
                    }
                }
            }
        })
    }
    
    // MARK: - Actions
    
    @IBAction func previousActionPressed() {
        WKInterfaceController.openParentApplication(["trigger": "previous"], reply: { (replyInfo, error) in
            if error != nil {
                println("Error: \(error.localizedDescription)")
            } else {
                // track should have moved
                NSTimer.scheduledTimerWithTimeInterval(0.5, target: self, selector: "refreshMetadata", userInfo: nil, repeats: false)
            }
        })
    }
    
    @IBAction func nextActionPressed() {
        WKInterfaceController.openParentApplication(["trigger": "next"], reply: { (replyInfo, error) in
            if error != nil {
                println("Error: \(error.localizedDescription)")
            } else {
                NSTimer.scheduledTimerWithTimeInterval(0.5, target: self, selector: "refreshMetadata", userInfo: nil, repeats: false)
            }
        })
    }
    
    @IBAction func playActionPressed() {
        if state == .Paused {
            state = .Playing
            self.prevTrack.setEnabled(true)
            self.nextTrack.setEnabled(true)
            playToggle.setBackgroundImageNamed("watch-pause")
            
            WKInterfaceController.openParentApplication(["trigger": "play"], reply: { (replyInfo, error) in
                if error != nil {
                    println("Error: \(error.localizedDescription)")
                } else {
                    NSTimer.scheduledTimerWithTimeInterval(0.5, target: self, selector: "refreshMetadata", userInfo: nil, repeats: false)
                }
            })
        } else {
            state = .Paused
            self.prevTrack.setEnabled(false)
            self.nextTrack.setEnabled(false)
            playToggle.setBackgroundImageNamed("watch-play")
            
            WKInterfaceController.openParentApplication(["trigger": "stop"], reply: { (replyInfo, error) in
                if error != nil {
                    println("Error: \(error.localizedDescription)")
                } else {
                    self.trackTime.stop()
                }
            })
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
