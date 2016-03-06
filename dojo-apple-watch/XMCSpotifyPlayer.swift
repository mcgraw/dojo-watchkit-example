//
//  XMCSpotifyPlayer.swift
//  dojo-apple-watch
//
//  Created by David McGraw on 2/21/15.
//  Copyright (c) 2015 David McGraw. All rights reserved.
//

import Foundation

class XMCSpotifyPlayer: NSObject, SPTAudioStreamingPlaybackDelegate, SPTAudioStreamingDelegate {
    
    class var sharedPlayer: XMCSpotifyPlayer  {
        struct Singleton {
            static let instance = XMCSpotifyPlayer()
        }
        return Singleton.instance
    }
    
    var session: SPTSession?
    var player: SPTAudioStreamingController?
    
    func beginAuthentication() {
        let auth = SPTAuth.defaultInstance()
        auth.clientID = kClientId
        auth.redirectURL = NSURL(string: kCallbackURL)
        auth.requestedScopes = [SPTAuthStreamingScope]
        
        let loginUrl = auth.loginURL
        UIApplication.sharedApplication().openURL(loginUrl)
    }
    
    func isAuthenticated() -> Bool {
        if let data: AnyObject = NSUserDefaults.standardUserDefaults().objectForKey(kSessionObjectDefaultsKey) {
            session = NSKeyedUnarchiver.unarchiveObjectWithData(data as! NSData) as? SPTSession
            if let status = session?.isValid() {
                return status
            }
        }
        return false
    }
    
    func renewSession(completed: (success: Bool) -> Void) {
        if session == nil {
            completed(success: false)
        } else {
            SPTAuth.defaultInstance().renewSession(session, callback: { (error, session) -> Void in
                if error != nil {
                    print("Renew session failed: \(error.localizedDescription)")
                    completed(success: false)
                } else {
                    // Update our defaults object
                    let sessionData = NSKeyedArchiver.archivedDataWithRootObject(session)
                    NSUserDefaults.standardUserDefaults().setObject(sessionData, forKey: kSessionObjectDefaultsKey)
                    NSUserDefaults.standardUserDefaults().synchronize()
                    
                    self.session = session
                    completed(success: true)
                }
            })
        }
    }
    
    func loginSession(playbackDelegate playbackDelegate: SPTAudioStreamingPlaybackDelegate?, delegate: SPTAudioStreamingDelegate?, completed: (success: Bool) -> Void) {
        assert(session != nil, "Don't call login if a session hasn't been created!")
        
        player = SPTAudioStreamingController(clientId: kClientId)
        player?.playbackDelegate = (playbackDelegate != nil) ? playbackDelegate : self
        player?.delegate = (delegate != nil) ? delegate : self
        player?.loginWithSession(session, callback: { (error) in
            if error != nil {
                print("Enabling playback failed: \(error.localizedDescription)")
                completed(success: false)
            } else {
                completed(success: true)
            }
        })
    }
    
    // MARK: - Player Controls
    
    func queueDefaultAlbum(completed: (success: Bool) -> Void) {
        if kPlayerPlaySampleTrack {
            queueSpotifyFreeSample(completed)
        }
        else {
            playPlayerQueue()
        }
    }
    
    //spotify:track:73DF2bQTw1tNzfMAttSKVG
    
    func queueSpotifyFreeSample(completed: (success: Bool) -> Void) {
        if let trackURI = NSURL(string: "spotify:track:73DF2bQTw1tNzfMAttSKVG"),
              track2URI = NSURL(string: "spotify:track:2V8NXVukTKfmpFwvCl6QBJ") {
            self.player?.playURIs([trackURI, track2URI], fromIndex: 0, callback: { (error) in
                if error != nil {
                    print("ERROR: \(error)")
                }
            })
        }
    }
    
    func togglePlay() {
        if let player = self.player {
            if player.isPlaying == true {
                stopPlayer()
            } else {
                playPlayerQueue()
            }
        }
    }
    
    func skipNext() {
        player?.skipNext({ (error) in
            if error != nil {
                print("Skip next failed: \(error.localizedDescription)")
            }
        })
    }
    
    func skipPrevious() {
        player?.skipPrevious({ (error) in
            if error != nil {
                print("Skip previous failed: \(error.localizedDescription)")
            }
        })
    }
    
    func stopPlayer() {
        player?.stop({ (error) in
            if error != nil {
                print("Something went wrong when trying to stop the player: \(error.localizedDescription)")
            }
        })
    }
    
    // TODO: Investigate how the Spotify SDK manages Album play
    func playPlayerQueue() {
//        if let albumURI = NSURL(string: "spotify:album:6ecx4OFG0nlUMqAi9OXQER") {
//            
//        }
    }
    
    func isPlaying() -> Bool {
        if let play = player {
            return play.isPlaying
        }
        return false
    }
    
    // MARK - Metadata
    
    func getAlbumArtForCurrentTrack(largestCover: Bool, completed: (image: UIImage?) -> Void) {
        getAlbumArtDataContent(largestCover, completed: { (data) in
            dispatch_async(dispatch_get_main_queue()) {
                if data != nil {
                    completed(image: UIImage(data: data!))
                } else {
                    completed(image: nil)
                }
            }
        })
    }

    func getAlbumArtAsDataForCurrentTrack(largestCover: Bool, completed: (data: NSData?) -> Void) {
        getAlbumArtDataContent(largestCover, completed: { (data) in
            dispatch_async(dispatch_get_main_queue()) {
                completed(data: data)
            }
        })
    }

    private func getAlbumArtDataContent(largestCover: Bool, completed: (data: NSData?) -> Void) {
        if player?.currentTrackMetadata == nil {
            completed(data: nil)
        } else {
            let albumUri = player?.currentTrackMetadata[SPTAudioStreamingMetadataAlbumURI] as! String
            SPTAlbum.albumWithURI(NSURL(string: albumUri), session: session, callback: { (error, obj) in
                if error != nil {
                    print("Something went wrong when trying get the album: \(error.localizedDescription)")
                    completed(data: nil)
                } else {
                    let album = obj as? SPTAlbum
                    var imagePath: NSURL?
                    if largestCover {
                        imagePath = album?.largestCover.imageURL
                    } else {
                        imagePath = album?.smallestCover.imageURL
                    }
                    
                    if let path = imagePath {
                        // Jump into the background to get the image
                        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)) {
                            if let data = NSData(contentsOfURL: path) {
                                completed(data: data)
                            }
                        }
                    }
                }
            })
        }
    }
    
    // MARK - Delegate
    
    func audioStreaming(audioStreaming: SPTAudioStreamingController!, didStartPlayingTrack trackUri: NSURL!) {
        print("Track started")

    }
    
    func audioStreaming(audioStreaming: SPTAudioStreamingController!, didChangeToTrack trackMetadata: [NSObject : AnyObject]!) {
        print("Changed track: \(trackMetadata)")
    }
}