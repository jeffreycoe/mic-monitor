//
//  AudioController.swift
//  Mic Monitor
//
//  Created by Jeffrey Coe on 10/22/16.
//  Copyright © 2016 Jeffrey Coe. All rights reserved.
//

import Foundation
import AVFoundation

class AudioController {
    
    init() {
        
    }
    
    public func getAudioDevices() -> Array<AVCaptureDevice> {
        var audioDevices: Array<AVCaptureDevice> = Array()
        let devices = AVCaptureDevice.devices(withMediaType: AVMediaTypeAudio)
        
        for device in devices! {
            if let device = device as? AVCaptureDevice {
                audioDevices.append(device)
            }
        }
        
        return audioDevices
    }
}
