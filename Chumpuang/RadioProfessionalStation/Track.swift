//
//  Track.swift
//  MyRadioStation
//
//  Created by JakkritS on 2/4/2559 BE.
//  Copyright © 2559 AppIllustrator. All rights reserved.
//

import UIKit

//*****************************************************************
// Track struct
//*****************************************************************

struct Track {
    var title: String = ""
    var artist: String = ""
    var artworkURL: String = ""
    var artworkImage = UIImage(named: "cd-album-art")
    var artworkLoaded = false
    var isPlaying: Bool = false
}
