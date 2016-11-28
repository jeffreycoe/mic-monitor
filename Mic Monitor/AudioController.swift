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
    enum AudioControllerError: Error {
        case AudioHardwareBadDevice
        case AudioControllerUnknownError
    }
    
    init() {
        
    }
    
    public func addAudioDeviceInUseSomewhereListener(device: AudioObjectID, proc: @escaping AudioObjectPropertyListenerProc) {
        var address: AudioObjectPropertyAddress = AudioObjectPropertyAddress()
        var inUseSomewhere = UInt32(0)
        address.mSelector = kAudioDevicePropertyDeviceIsRunningSomewhere
        address.mScope = kAudioObjectPropertyScopeGlobal
        address.mElement = kAudioObjectPropertyElementMaster
        
        do {
            try handleResult(result: AudioObjectAddPropertyListener(device, &address, proc, &inUseSomewhere))
        } catch AudioControllerError.AudioHardwareBadDevice {
            handleError(errorType: AudioControllerError.AudioHardwareBadDevice)
        } catch {
            handleError(errorType: AudioControllerError.AudioControllerUnknownError)
        }
    }
    
    public func isAudioDeviceInUseSomewhere(device: AudioObjectID) -> Bool {
        var inUseSomewhere = UInt32(0)
        var size = UInt32(MemoryLayout<UInt32>.size)
        var address: AudioObjectPropertyAddress = AudioObjectPropertyAddress()
        address.mSelector = kAudioDevicePropertyDeviceIsRunningSomewhere
        address.mScope = kAudioObjectPropertyScopeGlobal
        address.mElement = kAudioObjectPropertyElementMaster
        
        do {
            try handleResult(result: AudioObjectGetPropertyData(device, &address, 0, nil, &size, &inUseSomewhere))
        } catch AudioControllerError.AudioHardwareBadDevice {
            handleError(errorType: AudioControllerError.AudioHardwareBadDevice)
        } catch {
            handleError(errorType: AudioControllerError.AudioControllerUnknownError)
        }
        
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
        
        do {
            try handleResult(result: AudioObjectGetPropertyData(device, &address, 0, nil, &size, &deviceName))
        } catch AudioControllerError.AudioHardwareBadDevice {
            handleError(errorType: AudioControllerError.AudioHardwareBadDevice)
        } catch {
            handleError(errorType: AudioControllerError.AudioControllerUnknownError)
        }
    
        return deviceName as String
    }
    
    public func getAudioDevices() -> [AudioDeviceID] {
        var size = UInt32(0)
        var devices: [AudioDeviceID] = []
        var numOfDevices: Int = 0
        var address: AudioObjectPropertyAddress = AudioObjectPropertyAddress()
        address.mSelector = kAudioHardwarePropertyDevices
        address.mScope = kAudioObjectPropertyScopeGlobal
        address.mElement = kAudioObjectPropertyElementMaster
        
        do {
            try handleResult(result: AudioObjectGetPropertyDataSize(AudioObjectID(kAudioObjectSystemObject), &address, 0, nil, &size))
            
            numOfDevices = Int(size) / MemoryLayout<AudioDeviceID>.size
            devices = Array(repeating: AudioDeviceID(), count: numOfDevices)
            
            try handleResult(result: AudioObjectGetPropertyData(AudioObjectID(kAudioObjectSystemObject), &address, 0, nil, &size, &devices))
        } catch AudioControllerError.AudioHardwareBadDevice {
            handleError(errorType: AudioControllerError.AudioHardwareBadDevice)
        } catch {
            handleError(errorType: AudioControllerError.AudioControllerUnknownError)
        }
        
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
        
        do {
            try(handleResult(result: AudioObjectGetPropertyDataSize(device, &address, 0, nil, &size)))
            
            let bufferList = AudioBufferList.allocate(maximumBuffers: Int(size))
            try(handleResult(result: AudioObjectGetPropertyData(device, &address, 0, nil, &size, bufferList.unsafeMutablePointer)))
            
            let numOfBuffers = Int(bufferList.unsafeMutablePointer.pointee.mNumberBuffers)
            
            for i in 0 ..< numOfBuffers {
                channels += Int(bufferList[i].mNumberChannels)
            }
        } catch AudioControllerError.AudioHardwareBadDevice {
            handleError(errorType: AudioControllerError.AudioHardwareBadDevice)
        } catch {
            handleError(errorType: AudioControllerError.AudioControllerUnknownError)
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
        
        do {
            try handleResult(result: AudioObjectGetPropertyData(AudioObjectID(kAudioObjectSystemObject), &address, 0, nil, &size, &device))
        } catch AudioControllerError.AudioHardwareBadDevice {
            handleError(errorType: AudioControllerError.AudioHardwareBadDevice)
        } catch {
            handleError(errorType: AudioControllerError.AudioControllerUnknownError)
        }
        
        return device
    }
    
    public func handleResult(result: OSStatus) throws {
        if result != kAudioHardwareNoError {
            switch(result) {
            case kAudioHardwareBadDeviceError:
                throw AudioControllerError.AudioHardwareBadDevice
            default:
                throw AudioControllerError.AudioControllerUnknownError
            }
        }
    }
    
    public func handleError(errorType: Error) {
        switch(errorType) {
        case AudioControllerError.AudioHardwareBadDevice:
            NSLog("AudioController: Bad Device")
        case AudioControllerError.AudioControllerUnknownError:
            NSLog("AudioController: Unknown Error Occurred")
        default:
            NSLog("AudioController: Unknown Error Occurred")
        }
    }
}
