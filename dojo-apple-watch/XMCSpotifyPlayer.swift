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
        let loginUrl = auth.loginURLForClientId(kClientId, declaredRedirectURL: NSURL(string: kCallbackURL), scopes: [SPTAuthStreamingScope])
        UIApplication.sharedApplication().openURL(loginUrl)
    }
    
    func isAuthenticated() -> Bool {
        if let data: AnyObject = NSUserDefaults.standardUserDefaults().objectForKey(kSessionObjectDefaultsKey) {
            session = NSKeyedUnarchiver.unarchiveObjectWithData(data as NSData) as? SPTSession
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
            SPTAuth.defaultInstance().renewSession(session, withServiceEndpointAtURL: NSURL(string: kTokenRefreshUrl), callback: { (error, session) -> Void in
                if error != nil {
                    println("Renew session failed: \(error.localizedDescription)")
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
    
    func loginSession(#playbackDelegate: SPTAudioStreamingPlaybackDelegate?, delegate: SPTAudioStreamingDelegate?, completed: (success: Bool) -> Void) {
        assert(session != nil, "Don't call login if a session hasn't been created!")
        
        player = SPTAudioStreamingController(clientId: kClientId)
        player?.playbackDelegate = (playbackDelegate != nil) ? playbackDelegate : self
        player?.delegate = (delegate != nil) ? delegate : self
        player?.loginWithSession(session, callback: { (error) in
            if error != nil {
                println("Enabling playback failed: \(error.localizedDescription)")
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
            SPTRequest.requestItemAtURI(NSURL(string: "spotify:album:1ZuyuaB3hzsew72bxgCv5E"), withSession: session, callback: { (error, album) in
                if error != nil {
                    completed(success: false)
                } else {
                    self.player?.queueTrackProvider(album as SPTAlbum, clearQueue: true, callback: { (error) in
                        if error != nil {
                            println("Couldn't queue tracks: \(error.localizedDescription)")
                            completed(success: false)
                        } else {
                            completed(success: true)
                        }
                        
                        // Don't start immediately
                        self.stopPlayer()
                    })
                }
            })
        }
    }
    
    //spotify:track:73DF2bQTw1tNzfMAttSKVG
    
    func queueSpotifyFreeSample(completed: (success: Bool) -> Void) {
        SPTRequest.requestItemAtURI(NSURL(string: "spotify:track:73DF2bQTw1tNzfMAttSKVG"), withSession: session) { (error, track) -> Void in
            if error != nil {
                completed(success: false)
            } else {
                self.player?.queueTrackProvider(track as SPTTrack, clearQueue: true, callback: { (error) in
                    if error != nil {
                        println("Couldn't queue track: \(error.localizedDescription)")
                        completed(success: false)
                    } else {
                        completed(success: true)
                    }
                    
                    // Don't start immediately
                    self.stopPlayer()
                })
            }
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
                println("Skip next failed: \(error.localizedDescription)")
            }
        })
    }
    
    func skipPrevious() {
        player?.skipPrevious({ (error) in
            if error != nil {
                println("Skip previous failed: \(error.localizedDescription)")
            }
        })
    }
    
    func stopPlayer() {
        player?.stop({ (error) in
            if error != nil {
                println("Something went wrong when trying to stop the player: \(error.localizedDescription)")
            }
        })
    }
    
    func playPlayerQueue() {
        player?.queuePlay({ (error) in
            if error != nil {
                println("Something went wrong when trying to play the player: \(error.localizedDescription)")
            }
        })
    }
    
    func isPlaying() -> Bool {
        if let play = player {
            return play.isPlaying
        }
        return false
    }
    
    // MARK - Metadata
    
    func getAlbumArtForCurrentTrack(completed: (image: UIImage?) -> Void) {
        getAlbumArtDataContent { (data) -> Void in
            dispatch_async(dispatch_get_main_queue()) {
                if data != nil {
                    completed(image: UIImage(data: data!))
                } else {
                    completed(image: nil)
                }
            }
        }
    }
    
    func getAlbumArtAsDataForCurrentTrack(completed: (data: NSData?) -> Void) {
        getAlbumArtDataContent { (data) -> Void in
            dispatch_async(dispatch_get_main_queue()) {
                completed(data: data)
            }
        }
    }
    
    private func getAlbumArtDataContent(completed: (data: NSData?) -> Void) {
        if player?.currentTrackMetadata == nil {
            completed(data: nil)
        } else {
            let albumUri = player?.currentTrackMetadata[SPTAudioStreamingMetadataAlbumURI] as String
            SPTAlbum.albumWithURI(NSURL(string: albumUri), session: session, callback: { (error, obj) in
                if error != nil {
                    println("Something went wrong when trying get the album: \(error.localizedDescription)")
                    completed(data: nil)
                } else {
                    let album = obj as SPTAlbum
                    if let imagePath = album.largestCover.imageURL {
                        
                        // Jump into the background to get the image
                        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)) {
                            if let data = NSData(contentsOfURL: imagePath) {
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
        println("Track started")

    }
    
    func audioStreaming(audioStreaming: SPTAudioStreamingController!, didChangeToTrack trackMetadata: [NSObject : AnyObject]!) {
        println("Changed track: \(trackMetadata)")
    }
}