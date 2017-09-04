//
//  RadioStation.swift
//  MyRadioStation
//
//  Created by JakkritS on 2/4/2559 BE.
//  Copyright © 2559 AppIllustrator. All rights reserved.
//

import UIKit

//*****************************************************************
// Radio Station
//*****************************************************************

class RadioStation: NSObject {
    
    var stationName     : String
    var stationStreamURL: String
    var stationImageURL : String
    var stationDesc     : String
    var stationLongDesc : String
    var stationFrequency: String
    
    init(name: String, streamURL: String, imageURL: String, desc: String, frq: String, longDesc: String) {
        self.stationName      = name
        self.stationStreamURL = streamURL
        self.stationImageURL  = imageURL
        self.stationDesc      = desc
        self.stationLongDesc  = longDesc
        self.stationFrequency = frq
    }
    
    // Convenience init without longDesc
    convenience init(name: String, streamURL: String, imageURL: String, desc: String) {
        self.init(name: name, streamURL: streamURL, imageURL: imageURL, desc: desc, frq: "", longDesc: "")
    }
    
    //*****************************************************************
    // MARK: - JSON Parsing into object
    //*****************************************************************
    
    class func parseStation(stationJSON: JSON) -> (RadioStation) {
        
        let name      = stationJSON["name"].string ?? ""
        let streamURL = stationJSON["streamURL"].string ?? ""
        let imageURL  = stationJSON["imageURL"].string ?? ""
        let desc      = stationJSON["desc"].string ?? ""
        let longDesc  = stationJSON["longDesc"].string ?? ""
        let frequency = stationJSON["frequency"].string ?? ""
        
        let station = RadioStation(name: name, streamURL: streamURL, imageURL: imageURL, desc: desc, frq: frequency, longDesc: longDesc)
        return station
    }
    
}

