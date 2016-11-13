//
//  AudioController.swift
//  Mic Monitor
//
//  Created by Jeffrey Coe on 10/22/16.
//  Copyright © 2016 Jeffrey Coe. All rights reserved.
//

import Foundation
import AudioToolbox

class AudioController {
    
    init() {
        
    }
    
    public func isAudioDeviceInUseSomewhere(device: AudioObjectID) -> Bool {
        var inUseSomewhere = UInt32(0)
        var size = UInt32(MemoryLayout<UInt32>.size)
        var address: AudioObjectPropertyAddress = AudioObjectPropertyAddress()
        address.mSelector = kAudioDevicePropertyDeviceIsRunningSomewhere
        address.mScope = kAudioObjectPropertyScopeGlobal
        address.mElement = kAudioObjectPropertyElementMaster
        
        try handleResult(result: AudioObjectGetPropertyData(device, &address, 0, nil, &size, &inUseSomewhere))
        
        if inUseSomewhere == 1 {
            return true
        } else {
            return false
        }
    }
    
    public func getAudioDeviceName(device: AudioObjectID) -> String {
        var deviceName: CFString = "" as CFString
        var size = UInt32(MemoryLayout<CFString>.size)
        var address: AudioObjectPropertyAddress = AudioObjectPropertyAddress()
        address.mSelector = kAudioDevicePropertyDeviceNameCFString
        address.mScope = kAudioObjectPropertyScopeGlobal
        address.mElement = kAudioObjectPropertyElementMaster
        
        try handleResult(result: AudioObjectGetPropertyData(device, &address, 0, nil, &size, &deviceName))
        
        return deviceName as String
    }
    
    public func getAudioDevices() -> [AudioDeviceID] {
        var size = UInt32(0)
        var address: AudioObjectPropertyAddress = AudioObjectPropertyAddress()
        address.mSelector = kAudioHardwarePropertyDevices
        address.mScope = kAudioObjectPropertyScopeGlobal
        address.mElement = kAudioObjectPropertyElementMaster
        
        try handleResult(result: AudioObjectGetPropertyDataSize(AudioObjectID(kAudioObjectSystemObject), &address, 0, nil, &size))
        
        let numOfDevices = Int(size) / MemoryLayout<AudioDeviceID>.size
        var devices: [AudioDeviceID] = Array(repeating: AudioDeviceID(), count: numOfDevices)
        try handleResult(result: AudioObjectGetPropertyData(AudioObjectID(kAudioObjectSystemObject), &address, 0, nil, &size, &devices))
        
        return devices
    }
    
    public func getAudioInputDevices() -> [AudioDeviceID] {
        let devices: [AudioDeviceID] = getAudioDevices()
        var inputDevices: [AudioDeviceID] = []
        
        for device in devices {
            let channelCount = getAudioDeviceInputChannelCount(device: device)
            
            if channelCount > 0 {
                inputDevices.append(device)
            }
        }
        
        return inputDevices
    }
    
    public func getAudioDeviceInputChannelCount(device: AudioDeviceID) -> Int {
        var channels = 0
        var size = UInt32(0)
        var address = AudioObjectPropertyAddress()
        address.mSelector = kAudioDevicePropertyStreamConfiguration
        address.mScope = kAudioDevicePropertyScopeInput
        address.mElement = 0
        
        AudioObjectGetPropertyDataSize(device, &address, 0, nil, &size)
        
        var bufferList = AudioBufferList.allocate(maximumBuffers: Int(size))
        AudioObjectGetPropertyData(device, &address, 0, nil, &size, bufferList.unsafeMutablePointer)
        let numOfBuffers = Int(bufferList.unsafeMutablePointer.pointee.mNumberBuffers)
        
        for i in 0 ..< numOfBuffers {
            channels += Int(bufferList[i].mNumberChannels)
        }
        
        return channels
    }
    
    public func getDefaultAudioInputDevice() -> AudioDeviceID {
        var device: AudioDeviceID = 0;
        var size: UInt32 = UInt32(MemoryLayout<AudioDeviceID>.size)
        var address: AudioObjectPropertyAddress = AudioObjectPropertyAddress()
        address.mSelector = kAudioHardwarePropertyDefaultInputDevice
        address.mScope = kAudioObjectPropertyScopeGlobal
        address.mElement = kAudioObjectPropertyElementMaster
        try handleResult(result: AudioObjectGetPropertyData(AudioObjectID(kAudioObjectSystemObject), &address, 0, nil, &size, &device))
        
        return device
    }
    
    public func handleResult(result: OSStatus) {
        if result != kAudioHardwareNoError {
            NSError(domain: NSOSStatusErrorDomain, code: Int(result), userInfo: nil)
        }
    }
}
