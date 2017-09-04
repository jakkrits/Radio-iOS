//
//  NowPlayingViewController.swift
//  RadioProfessionalStation
//
//  Created by JakkritS on 2/9/2559 BE.
//  Copyright © 2559 AppIllustrator. All rights reserved.
//

import UIKit
import MediaPlayer
import AVFoundation
import AVKit
import Material
import Spring

protocol NowPlayingViewControllerDelegate: class {
    func songMetaDataDidUpdate(track: Track)
    func artworkDidUpdate(track: Track)
    func trackPlayingToggled(track: Track)
}

class NowPlayingViewController: UIViewController {
    
    @IBOutlet weak var pauseButton: UIButton!
    @IBOutlet weak var playButton: FabButton!
    @IBOutlet weak var radioDisplayImageView: SpringImageView!
    @IBOutlet weak var volumeSlider: UISlider!
    @IBOutlet weak var frequencyLabel: UILabel!
    @IBOutlet weak var stationIDLabel: UILabel!
    @IBOutlet weak var playingStatusLabel: SpringLabel!
    @IBOutlet weak var volumeView: UIView!
    @IBOutlet weak var artistLabel: SpringLabel!
    @IBOutlet weak var artworkImageView: SpringImageView!
    
    var currentStation: RadioStation!
    var currentTrack: Track?
    var downloadTask: NSURLSessionDownloadTask?
    var justBecameActive = false
    var newStation = true
    let radioPlayer = Player.radio
    var track = Track()
    var mpVolumeSlider = UISlider()
    let fabButton = FabButton()
    var playerItem: AVPlayerItem?
    
    var broadcastStatus: Bool = true {
        didSet {
            print("Current status = \(broadcastStatus)")
        }
    }
    var isBroadcasting: Bool {
        let jsonString = "https://cp.hostpleng.com:2199/rpc/sutep2/streaminfo.get"
        guard let jsonURL = NSURL(string: jsonString) else {
            print("URL unavailable")
            return false
        }
        guard let data = NSData(contentsOfURL: jsonURL) else {
            print("Data unavailable")
            return false
        }
        let json = JSON(data: data)
        print(json["data"][0]["source"])
        if json["data"][0]["source"] == "ไม่" {
            broadcastStatus = false
            return broadcastStatus
        } else {
            broadcastStatus = true
            return broadcastStatus
        }
    }
    
    weak var delegate: NowPlayingViewControllerDelegate?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        loadStationsFromJSON()
        setupVolume()
        setupNotifications()
        setupView()
        
        self.becomeFirstResponder()
        
        playingStatusLabel.text = ""
        artistLabel.text = ""
        
        // Set AVFoundation category for background audio
        var error: NSError?
        var success: Bool
        do {
            try AVAudioSession.sharedInstance().setCategory(
                AVAudioSessionCategoryPlayAndRecord,
                withOptions: .DefaultToSpeaker)
            success = true
        } catch let error1 as NSError {
            error = error1
            success = false
        }
        if !success {
            if DEBUG_LOG { print("Failed to set audio session category.  Error: \(error)") }
        }
        
    }
    
    override func viewDidAppear(animated: Bool) {
        if isBroadcasting == false {
            NSNotificationCenter.defaultCenter().postNotificationName("Not_Broadcasting", object: nil)
            let alertController = UIAlertController(title: "Station Down", message: "Station is not broadcasting. Please check back later", preferredStyle: .Alert)
            let action = UIAlertAction(title: "OK", style: .Default, handler: nil)
            alertController.addAction(action)
            playButtonEnable(false)
            self.presentViewController(alertController, animated: true, completion: nil)
        } else {
            NSNotificationCenter.defaultCenter().postNotificationName("Currently_Broadcasting", object: nil)
        }
        
    }
    override func viewWillAppear(animated: Bool) {
        // If a track is playing, display title & artist information and animation
        if currentTrack != nil && currentTrack!.isPlaying {
            let title = currentStation!.stationName + ": " + currentTrack!.title + " - " + currentTrack!.artist + "..."
            playingStatusLabel.text = title
        } else {
            playingStatusLabel.text = "Tap to Play"
        }
    }
    
    override func canBecomeFirstResponder() -> Bool {
        return true
    }
    
    // FabButton handler.
    func handleFabButton() {
        print(__FUNCTION__)
        sideNavigationViewController?.toggleLeftView()
    }
    
    //MARK: - IBActions
    @IBAction func playButtonPressed() {
        //Setup Player
        if radioPlayer.player == nil {
            playerItem = AVPlayerItem(URL: NSURL(string: currentStation.stationStreamURL)!)
            playerItem!.addObserver(self, forKeyPath: "timedMetadata", options: [.New, .Prior, .Initial, .Old], context: nil)
            radioPlayer.player = AVPlayer(playerItem: playerItem!)
        }
        
        playButtonEnable(false)
        self.delegate?.trackPlayingToggled(self.track)
        self.radioDisplayImageView.animate()
        radioPlayer.player?.play()
    }
    
    @IBAction func pauseButtonPressed() {
        if isBroadcasting == true {
            track.isPlaying = false
            radioPlayer.player?.pause()
            playButtonEnable()
            updateAlbumArtwork()
            artistLabel.text = track.artist
            playingStatusLabel.text = track.title
        } else {
            artistLabel.text = "Station Down"
            playingStatusLabel.text = "Not braodcasting..."
            let alertController = UIAlertController(title: "Station Down", message: "Station is not broadcasting. Please check back later", preferredStyle: .Alert)
            let action = UIAlertAction(title: "OK", style: .Default, handler: nil)
            alertController.addAction(action)
            self.presentViewController(alertController, animated: true, completion: nil)
        }
    }
    
    @IBAction func volumeSliderChanged(sender: UISlider) {
        mpVolumeSlider.value = sender.value
    }
    
    
    func playButtonEnable(enabled: Bool = true) {
        if enabled {
            playButton.enabled = true
            pauseButton.enabled = false
            track.isPlaying = false
        } else {
            playButton.enabled = false
            pauseButton.enabled = true
            track.isPlaying = true
        }
    }
    
    func broadcastingStatus(notification: NSNotification) {
        print(__FUNCTION__)
        switch notification.name {
        case "Not_Broadcasting":
            artistLabel.text = "Station Down"
            playingStatusLabel.text = "Not braodcasting..."
        case "Currently_Broadcasting":
            artistLabel.text = "Station is braodcasting"
            playingStatusLabel.text = "Press to Play"
        default: print("whateve!")
        }
    }
    
    func loadStationsFromJSON() {
        
        // Turn on network indicator in status bar
        UIApplication.sharedApplication().networkActivityIndicatorVisible = true
        
        // Get the Radio Stations
        DataManager.getStationDataWithSuccess() { (data) in
            
            if DEBUG_LOG { print("Stations JSON Found") }
            
            let json = JSON(data: data)
            
            let station = RadioStation.parseStation(json["stations"][0])
            
            dispatch_async(dispatch_get_main_queue()) {
                self.currentStation = station
                self.stationIDLabel.text = station.stationName
                self.frequencyLabel.text = station.stationFrequency
                self.view.setNeedsDisplay()
            }
            
            
            // Turn off network indicator in status bar
            UIApplication.sharedApplication().networkActivityIndicatorVisible = false
        }
    }
    
    //*****************************************************************
    // MARK: - Setups
    //*****************************************************************
    func setupView() {
        //self.view.backgroundColor = UIColor(red:0.91, green:0.26, blue:0.38, alpha:1)
        // Toggle SideNavigationViewController.
        let img: UIImage? = UIImage(named: "microphone")
        
        fabButton.backgroundColor = UIColor(red:0.27, green:0.54, blue:0.99, alpha:1)
        fabButton.setImage(img, forState: .Normal)
        fabButton.setImage(img, forState: .Highlighted)
        fabButton.addTarget(self, action: "handleFabButton", forControlEvents: .TouchUpInside)
        view.addSubview(fabButton)
        fabButton.translatesAutoresizingMaskIntoConstraints = false
        MaterialLayout.alignFromBottomRight(view, child: fabButton, bottom: 16, right: 16)
        MaterialLayout.size(view, child: fabButton, width: 64, height: 64)
        
        playButton.backgroundColor = UIColor.clearColor()
    }
    
    func setupVolume() {
        self.volumeView.backgroundColor = UIColor.clearColor()
        let volumeView = MPVolumeView(frame: self.volumeView.bounds)
        for view in volumeView.subviews {
            let uiview: UIView = view as UIView
            if (uiview.description as NSString).rangeOfString("MPVolumeSlider").location != NSNotFound {
                mpVolumeSlider = (uiview as! UISlider)
            }
        }
    }
    
    func setupNotifications() {
        // Notification for when app becomes active
        NSNotificationCenter.defaultCenter().addObserver(self,
            selector: "didBecomeActiveNotificationReceived",
            name:"UIApplicationDidBecomeActiveNotification",
            object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "broadcastingStatus:", name: "Not_Broadcasting", object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "broadcastingStatus:", name: "Currently_Broadcasting", object: nil)
    }
    
    func showInfo() {
        performSegueWithIdentifier("ShowInfoSegue", sender: self)
    }
    
    deinit {
        NSNotificationCenter.defaultCenter().removeObserver(self,
            name:"UIApplicationDidBecomeActiveNotification",
            object: nil)
        playerItem?.removeObserver(self, forKeyPath: "timedMetadata")
        NSNotificationCenter.defaultCenter().removeObserver(self, name: "Currently_Broadcasting", object: nil)
        NSNotificationCenter.defaultCenter().removeObserver(self, name: "Not_Broadcasting", object: nil)
    }
    
    func didBecomeActiveNotificationReceived() {
        // View became active
        justBecameActive = true
        updateAlbumArtwork()
    }
    
    override func observeValueForKeyPath(keyPath: String?, ofObject object: AnyObject?, change: [String : AnyObject]?, context: UnsafeMutablePointer<Void>) {
        if keyPath != "timedMetadata" { return }
        
        let data: AVPlayerItem = object as! AVPlayerItem
        
        guard let tmdata = data.timedMetadata else {
            return
        }
        
        let firstMeta = tmdata[0]
        let metaData = firstMeta.value as! String
        
        var stringParts = [String]()
        if metaData.rangeOfString(" - ") != nil {
            stringParts = metaData.componentsSeparatedByString(" - ")
        } else {
            stringParts = metaData.componentsSeparatedByString("-")
        }
        
        // Set artist & songvariables
        //Decoding
        let artist = NSString(string: stringParts[0])
        let encodeToThai = CFStringConvertEncodingToNSStringEncoding(CFStringEncoding(CFStringEncodings.ISOLatinThai.rawValue))
        let artistData = artist.dataUsingEncoding(NSISOLatin1StringEncoding)!
        let decodedArtist = NSString(data: artistData, encoding: encodeToThai)!
        self.track.artist = "\(decodedArtist)"
        
        if stringParts.count > 1 {
            let songTitle = NSString(string: stringParts[1])
            let titleData = songTitle.dataUsingEncoding(NSISOLatin1StringEncoding)!
            let decodedTitle = NSString(data: titleData, encoding: encodeToThai)!
            self.track.title = "\(decodedTitle)"
        }
        
        if track.artist == "" && track.title == "" {
            track.artist = currentStation.stationDesc
            track.title = currentStation.stationName
        }
        
        print("----> track.title = \(self.track.title)")
        print("----> track.artist = \(self.track.artist)")
        
        dispatch_async(dispatch_get_main_queue()) {
            //Update Labels
            self.playingStatusLabel.text = self.track.title
            self.playingStatusLabel.animation = "flash"
            self.playingStatusLabel.duration = 1.8
            self.playingStatusLabel.damping = 1
            self.playingStatusLabel.repeatCount = 150
            self.playingStatusLabel.animate()
            self.artistLabel.text = self.track.artist
            
            let animation = CABasicAnimation(keyPath: "cornerRadius")
            animation.fromValue = self.fabButton.layer.cornerRadius
            // Set the completion value
            animation.toValue = 0
            animation.repeatCount = 15
            
            self.fabButton.backgroundColor = UIColor(red:0.27, green:0.54, blue:0.99, alpha:0.25)
            
            self.fabButton.layer.addAnimation(animation, forKey: "cornerRadius")
            
            
            // Update Stations Screen
            self.delegate?.songMetaDataDidUpdate(self.track)
            
            
            // Query API for album art
            self.resetAlbumArtwork()
            self.queryAlbumArt()
            self.updateLockScreen()
            
        }
    }
    
    //*****************************************************************
    // MARK: - Album Art
    //*****************************************************************
    
    func resetAlbumArtwork() {
        print(__FUNCTION__)
        track.artworkLoaded = false
        track.artworkURL = currentStation.stationImageURL
        updateAlbumArtwork()
    }
    
    func updateAlbumArtwork() {
        print(__FUNCTION__)
        if track.artworkURL.rangeOfString("http") != nil {
            
            // Attempt to download album art from LastFM
            if let url = NSURL(string: track.artworkURL) {
                
                self.downloadTask = self.artworkImageView.loadImageWithURL(url) {
                    (image) in
                    // Update track struct
                    self.track.artworkImage = image
                    self.track.artworkLoaded = true
                    
                    // Turn off network activity indicator
                    UIApplication.sharedApplication().networkActivityIndicatorVisible = false
                    
                    // Animate artwork
                    self.artworkImageView.animation = "pop"
                    self.artworkImageView.duration = 2
                    self.artworkImageView.animate()
                    
                    // Update lockscreen
                    self.updateLockScreen()
                    
                    // Call delegate function that artwork updated
                    self.delegate?.artworkDidUpdate(self.track)
                }
            }
            
        } else if track.artworkURL != "" {
            // Local artwork
            self.artworkImageView.image = UIImage(named: track.artworkURL)
            track.artworkImage = artworkImageView.image
            track.artworkLoaded = true
            
            // Call delegate function that artwork updated
            self.delegate?.artworkDidUpdate(self.track)
            
        } else {
            // No Station or LastFM art found, use default art
            self.artworkImageView.image = UIImage(named: "cd-album-art")
            track.artworkImage = artworkImageView.image
        }
        
        // Force app to update display
        self.view.setNeedsDisplay()
        
    }
    
    // Call LastFM API to get album art url
    
    func queryAlbumArt() {
        
        UIApplication.sharedApplication().networkActivityIndicatorVisible = true
        
        // Construct either LastFM or iTunes API call URL
        let queryURL: String
        if useLastFM {
            queryURL = String(format: "http://ws.audioscrobbler.com/2.0/?method=track.getInfo&api_key=%@&artist=%@&track=%@&format=json", apiKey, track.artist, track.title)
        } else {
            queryURL = String(format: "https://itunes.apple.com/search?term=%@+%@&entity=song", track.artist, track.title)
        }
        
        let escapedURL = queryURL.stringByAddingPercentEncodingWithAllowedCharacters(NSCharacterSet.URLQueryAllowedCharacterSet())
        
        // Query API
        DataManager.getTrackDataWithSuccess(escapedURL!) { (data) in
            
            if DEBUG_LOG {
                print("API SUCCESSFUL RETURN")
                print("url: \(escapedURL!)")
            }
            
            let json = JSON(data: data)
            if useLastFM {
                // Get Largest Sized LastFM Image
                if let imageArray = json["track"]["album"]["image"].array {
                    
                    let arrayCount = imageArray.count
                    let lastImage = imageArray[arrayCount - 1]
                    
                    if let artURL = lastImage["#text"].string {
                        
                        // Check for Default Last FM Image
                        if artURL.rangeOfString("/noimage/") != nil {
                            self.resetAlbumArtwork()
                            
                        } else {
                            // LastFM image found!
                            self.track.artworkURL = artURL
                            self.track.artworkLoaded = true
                            self.updateAlbumArtwork()
                        }
                        
                    } else {
                        self.resetAlbumArtwork()
                    }
                } else {
                    self.resetAlbumArtwork()
                }
                
            } else {
                print("USE ITUNES")
                if let artURL = json["results"][0]["artworkUrl100"].string {
                    if DEBUG_LOG {
                        //print("iTunes artURL: \(artURL)")
                    }
                    //switch to 300x300 px
                    let newArtURL = artURL.stringByReplacingOccurrencesOfString("100x100bb.jpg", withString: "300x300bb.jpg")
                    self.track.artworkURL = newArtURL
                    self.track.artworkLoaded = true
                    self.updateAlbumArtwork()
                } else {
                    self.resetAlbumArtwork()
                }
            }
            
        }
    }
    
    //*****************************************************************
    // MARK: - MPNowPlayingInfoCenter (Lock screen)
    //*****************************************************************
    
    func updateLockScreen() {
        
        // Update notification/lock screen
        let albumArtwork = MPMediaItemArtwork(image: track.artworkImage!)
        MPNowPlayingInfoCenter.defaultCenter().nowPlayingInfo = [
            MPMediaItemPropertyArtist: track.artist,
            MPMediaItemPropertyTitle: track.title,
            MPMediaItemPropertyArtwork: albumArtwork
        ]
        
    }
    
    override func remoteControlReceivedWithEvent(receivedEvent: UIEvent?) {
        super.remoteControlReceivedWithEvent(receivedEvent)
        
        if receivedEvent!.type == UIEventType.RemoteControl {
            
            switch receivedEvent!.subtype {
            case .RemoteControlPlay:
                playButtonPressed()
            case .RemoteControlPause:
                pauseButtonPressed()
            default:
                break
            }
        }
    }
}
