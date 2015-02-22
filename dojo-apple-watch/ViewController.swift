//
//  ViewController.swift
//  dojo-apple-watch
//
//  Created by David McGraw on 11/19/14.
//  Copyright (c) 2014 David McGraw. All rights reserved.
//

import UIKit

class ViewController: UIViewController, SPTAudioStreamingDelegate, SPTAudioStreamingPlaybackDelegate {
    
    @IBOutlet weak var prevAction: UIButton!
    @IBOutlet weak var nextAction: UIButton!
    @IBOutlet weak var playAction: UIButton!
    @IBOutlet weak var loginAction: UIButton!
    @IBOutlet weak var albumArt: UIImageView! {
        didSet {
            let gradient = CAGradientLayer()
            gradient.frame = albumArt.bounds
            gradient.colors = [ UIColor(red: 0, green: 0, blue: 0, alpha: 0).CGColor, UIColor(red: 0, green: 0, blue: 0, alpha: 1).CGColor ]
            gradient.startPoint = CGPointMake(0.5, 1)
            gradient.endPoint = CGPointMake(0.5, 0)
            albumArt?.layer.mask = gradient
            albumArt?.layer.cornerRadius = 8.0
            albumArt?.layer.masksToBounds = true
        }
    }
    @IBOutlet weak var trackTitle: UILabel!
    @IBOutlet weak var trackTime: UILabel!
    
    var hasQueued = false
    var trackTimeInterval: NSTimeInterval = 0.0
    var trackTimer: NSTimer?
    var session: SPTSession?
    var player: SPTAudioStreamingController?
    
    required init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "loginAvailableSession", name: kSessionWasUpdated, object: nil)
        
        // Handle Spotify Session
        if let data: AnyObject = NSUserDefaults.standardUserDefaults().objectForKey(kSessionObjectDefaultsKey) {
            session = NSKeyedUnarchiver.unarchiveObjectWithData(data as NSData) as? SPTSession
            if let valid = session?.isValid() {
                loginAvailableSession()
            } else {
                SPTAuth.defaultInstance().renewSession(session, withServiceEndpointAtURL: NSURL(string: kTokenRefreshUrl), callback: { (error, session) -> Void in
                    if error != nil {
                        println("Renew session failed: \(error.localizedDescription)")
                    } else {
                        // Update our defaults object
                        let sessionData = NSKeyedArchiver.archivedDataWithRootObject(session)
                        NSUserDefaults.standardUserDefaults().setObject(sessionData, forKey: kSessionObjectDefaultsKey)
                        NSUserDefaults.standardUserDefaults().synchronize()
                        
                        self.session = session
                        self.loginAvailableSession()
                    }
                })
            }
        } else {
            // if we don't have an archived session object, the default interface will reveal a log in action
        }
    }
    
    func loginAvailableSession() {
        player = SPTAudioStreamingController(clientId: kClientId)
        player?.playbackDelegate = self
        player?.delegate = self
        player?.loginWithSession(session, callback: { (error) in
            if error != nil {
                println("Enabling playback failed: \(error.localizedDescription)")
                NSNotificationCenter.defaultCenter().postNotificationName(kSessionLoginDidFail, object: nil)
            } else {
                NSNotificationCenter.defaultCenter().postNotificationName(kSessionLoginDidSucceed, object: nil)
            }
        })
    }
    
    @IBAction func loginActionPressed(sender: AnyObject) {
        let auth = SPTAuth.defaultInstance()
        let loginUrl = auth.loginURLForClientId(kClientId, declaredRedirectURL: NSURL(string: kCallbackURL), scopes: [SPTAuthStreamingScope])
        UIApplication.sharedApplication().openURL(loginUrl)
    }

    @IBAction func playTrack(sender: AnyObject) {
        if let player = self.player {
            if player.isPlaying == true {
                stopPlayer()
            } else {
                playPlayer()
            }
        }
    }
    
    @IBAction func skipNext(sender: AnyObject) {
        player?.skipNext({ (error) in
            if error != nil {
                println("Skip next failed: \(error.localizedDescription)")
                UIAlertView(title: "Error", message: "Couldn't skip to next track", delegate: nil, cancelButtonTitle: "OK").show()
            } else {
                self.playQueue()
            }
        })
    }
    
    @IBAction func skipPrevious(sender: AnyObject) {
        player?.skipPrevious({ (error) in
            if error != nil {
                println("Skip previous failed: \(error.localizedDescription)")
                UIAlertView(title: "Error", message: "Couldn't skip to previous track", delegate: nil, cancelButtonTitle: "OK").show()
            } else {
                self.playQueue()
            }
        })
    }
    
    func authenticateWithSpotify() {
        let auth = SPTAuth.defaultInstance()
        let loginUrl = auth.loginURLForClientId(kClientId, declaredRedirectURL: NSURL(string: kCallbackURL), scopes: [SPTAuthStreamingScope])
        UIApplication.sharedApplication().openURL(loginUrl)
    }
    
    // MARK: - Private Realm

    private func playPlayer() {
        SPTRequest.requestItemAtURI(NSURL(string: "spotify:album:1ZuyuaB3hzsew72bxgCv5E"), withSession: session, callback: { (error, album) in
            if error != nil {
                UIAlertView(title: "Error", message: "Couldn't locate album", delegate: nil, cancelButtonTitle: "OK").show()
            } else {
                self.player?.queueTrackProvider(album as SPTAlbum, clearQueue: false, callback: { (error) in
                    if error != nil {
                        println("Couldn't queue tracks: \(error.localizedDescription)")
                        UIAlertView(title: "Error", message: "Couldn't play player", delegate: nil, cancelButtonTitle: "OK").show()
                    } else {
                        self.playQueue()
                        self.hasQueued = true
                    }
                })
            }
        })
    }
    
    private func playQueue() {
        player?.queuePlay({ (error) in
            if error != nil {
                println("Something went wrong when trying to play the player: \(error.localizedDescription)")
                UIAlertView(title: "Error", message: "Couldn't play player", delegate: nil, cancelButtonTitle: "OK").show()
            } else {
                self.hasQueued = true
            }
        })
    }
    
    private func stopPlayer() {
        player?.stop({ (error) in
            if error != nil {
                println("Something went wrong when trying to stop the player: \(error.localizedDescription)")
                UIAlertView(title: "Error", message: "Couldn't stop player", delegate: nil, cancelButtonTitle: "OK").show()
            }
        })
    }
    
    private func refreshAlbumArt() {
        if player?.currentTrackMetadata == nil {
            albumArt.image = UIImage()
        } else {
            let albumUri = player?.currentTrackMetadata[SPTAudioStreamingMetadataAlbumURI] as String
            SPTAlbum.albumWithURI(NSURL(string: albumUri), session: session, callback: { (error, obj) in
                if error != nil {
                    println("Something went wrong when trying get the album: \(error.localizedDescription)")
                } else {
                    let album = obj as SPTAlbum
                    if let imagePath = album.largestCover.imageURL {
                        
                        // Jump into the background to get the image
                        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)) {
                            if let data = NSData(contentsOfURL: imagePath) {
                                
                                // Set the image over on the main thread
                                dispatch_async(dispatch_get_main_queue()) {
                                    self.albumArt.image = UIImage(data: data)
                                    
                                    UIView.animateWithDuration(0.225, animations: {
                                        self.albumArt.alpha = 1.0
                                    })
                                }
                            }
                        }
                    }
                }
            })
        }
    }
    
    // MARK: - Streaming Delegate
    
    func audioStreaming(audioStreaming: SPTAudioStreamingController!, didChangePlaybackStatus isPlaying: Bool) {
        println("Playback status changed: \(isPlaying)")
        
        if isPlaying == true {
            self.playAction.setImage(UIImage(named: "player-pause"), forState: UIControlState.Normal)
            self.prevAction.enabled = true
            self.nextAction.enabled = true
        } else {
            self.playAction.setImage(UIImage(named: "player-play"), forState: UIControlState.Normal)
            self.prevAction.enabled = false
            self.nextAction.enabled = false
            self.trackTimer?.invalidate()
            
            UIView.animateWithDuration(0.225, animations: {
                self.trackTitle.alpha = 0.0
                self.trackTime.alpha = 0.0
            })
        }
    }
    
    func audioStreaming(audioStreaming: SPTAudioStreamingController!, didChangeToTrack trackMetadata: [NSObject : AnyObject]!) {
        println("Changed track: \(trackMetadata)")
        
        UIView.animateWithDuration(0.225, animations: {
            self.trackTitle.alpha = 0.0
            self.trackTime.alpha = 0.0
        }, { _ in
            self.trackTitle.text = trackMetadata[SPTAudioStreamingMetadataTrackName] as? String
            
            self.trackTimeInterval = trackMetadata[SPTAudioStreamingMetadataTrackDuration] as NSTimeInterval
            self.trackTime.text = "Now Playing"
            
            UIView.animateWithDuration(0.225, animations: {
                self.trackTitle.alpha = 1.0
                self.trackTime.alpha = 1.0
            })
        })
        
        startTrackTimer()
    }
    
    func audioStreaming(audioStreaming: SPTAudioStreamingController!, didStartPlayingTrack trackUri: NSURL!) {
        println("Track started")
        refreshAlbumArt()
    }
    
    func audioStreaming(audioStreaming: SPTAudioStreamingController!, didFailToPlayTrack trackUri: NSURL!) {
        println("Playback failed to play")
    }
    
    func audioStreamingDidLogin(audioStreaming: SPTAudioStreamingController!) {
        println("Did login")
        UIView.animateWithDuration(0.225, animations: {
            self.prevAction.alpha = 1
            self.nextAction.alpha = 1
            self.playAction.alpha = 1
            self.loginAction.alpha = 0
        })
    }
    
    func audioStreamingDidLogout(audioStreaming: SPTAudioStreamingController!) {
        println("Did logout")
        UIView.animateWithDuration(0.225, animations: {
            self.prevAction.alpha = 0
            self.nextAction.alpha = 0
            self.playAction.alpha = 0
            self.loginAction.alpha = 0
        })
    }
    
    // MARK: - Timer
    
    func startTrackTimer() {
        if let timer = trackTimer {
            timer.invalidate()
            trackTimer = nil
        }
        
        trackTimer = NSTimer.scheduledTimerWithTimeInterval(1.0, target: self, selector: "updateTrackTimer", userInfo: nil, repeats: true)
    }
    
    func updateTrackTimer() {
        let minutes = floor(trackTimeInterval / 60.0)
        let seconds = round(trackTimeInterval - minutes * 60.0)
        
        var strMinutes = "\(Int(minutes))"
        var strSeconds = "\(Int(seconds))"
        
        if seconds < 10 {
            strSeconds = "0" + strSeconds
        }
        
        if seconds == 60 {
            strSeconds = "00"
            strMinutes = "\(Int(minutes + 1))"
        }
        
        if trackTimeInterval <= 0 {
            trackTimer?.invalidate()
        } else {
            trackTime.text = "\(strMinutes):\(strSeconds)"
            trackTimeInterval--
        }
    }
}

