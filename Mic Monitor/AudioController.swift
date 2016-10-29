//
//  AudioController.swift
//  Mic Monitor
//
//  Created by Jeffrey Coe on 10/22/16.
//  Copyright © 2016 Jeffrey Coe. All rights reserved.
//

import Foundation
import AVFoundation

func isMicInUse() -> Bool {
    var micInUse = false
    var session = AVAudioSession.sharedInstance()
    
    return micInUse
}
