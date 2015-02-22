//
//  XMCViewController.swift
//  dojo-apple-watch
//
//  Created by David McGraw on 11/19/14.
//  Copyright (c) 2014 David McGraw. All rights reserved.
//

import UIKit

class XMCViewController: UIViewController, SPTAudioStreamingDelegate, SPTAudioStreamingPlaybackDelegate {
    
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
    
    var trackTimeInterval: NSTimeInterval = 0.0
    var trackTimer: NSTimer?
    
    required init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "loginAvailableSession:", name: kSessionWasUpdated, object: nil)
        
        // If we have a valid session then we can login
        if XMCSpotifyPlayer.sharedPlayer.isAuthenticated() {
            attemptLogin()
        } else {
            // If not, try to renew our session
            XMCSpotifyPlayer.sharedPlayer.renewSession({ (success) in
                if success {
                    self.attemptLogin()
                } else {
                    // The user needs to go through the authentication process
                }
            })
        }
    }
    
    func loginAvailableSession(sender: NSNotification) {
        attemptLogin() // new session, login with it
    }
    
    func attemptLogin() {
        XMCSpotifyPlayer.sharedPlayer.loginSession(playbackDelegate: self, delegate: self, { (success) in
            if success == false {
                // Something went wrong! Assume we need to re-auth for now.
                self.showLoginButton()
            } else {
                XMCSpotifyPlayer.sharedPlayer.queueDefaultAlbum({ (success) in
                    // We should be good to go!
                })
            }
        })
    }
    
    // MARK: - Actions
    
    @IBAction func loginActionPressed(sender: AnyObject) {
        XMCSpotifyPlayer.sharedPlayer.beginAuthentication()
    }

    @IBAction func playTrack(sender: AnyObject) {
        XMCSpotifyPlayer.sharedPlayer.togglePlay()
    }
    
    @IBAction func skipNext(sender: AnyObject) {
        XMCSpotifyPlayer.sharedPlayer.skipNext()
    }
    
    @IBAction func skipPrevious(sender: AnyObject) {
        XMCSpotifyPlayer.sharedPlayer.skipPrevious()
    }
    
    // MARK: - Private Realm
    
    private func refreshAlbumArt() {
        XMCSpotifyPlayer.sharedPlayer.getAlbumArtForCurrentTrack { (image) in
            self.albumArt.image = image
            
            UIView.animateWithDuration(0.225, animations: {
                self.albumArt.alpha = 1.0
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
        hideLoginButton()
    }
    
    func audioStreamingDidLogout(audioStreaming: SPTAudioStreamingController!) {
        println("Did logout")
        showLoginButton()
    }
    
    // MARK: - Layout
    
    func hideLoginButton() {
        UIView.animateWithDuration(0.225, animations: {
            self.prevAction.alpha = 1
            self.nextAction.alpha = 1
            self.playAction.alpha = 1
            self.loginAction.alpha = 0
        })
    }
    
    func showLoginButton() {
        UIView.animateWithDuration(0.225, animations: {
            self.prevAction.alpha = 0
            self.nextAction.alpha = 0
            self.playAction.alpha = 0
            self.trackTime.alpha = 0
            self.trackTitle.alpha = 0
            self.loginAction.alpha = 1
        })
    }
    
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

