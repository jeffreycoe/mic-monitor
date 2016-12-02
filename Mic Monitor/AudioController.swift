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
        case AudioHardwareNotRunning
        case AudioHardwareUnspecifiedError
        case AudioHardwareUnknownProperty
        case AudioHardwareBadPropertySize
        case AudioHardwareIllegalOperation
        case AudioHardwareBadObject
        case AudioHardwareBadDevice
        case AudioHardwareBadStream
        case AudioHardwareUnsupportedOperation
        case AudioDeviceUnsupportedFormat
        case AudioDevicePermissionsError
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
        } catch let e {
            handleError(errorType: e)
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
        } catch let e {
            handleError(errorType: e)
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
        } catch let e {
            handleError(errorType: e)
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
        } catch let e {
            handleError(errorType: e)
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
        } catch let e {
            handleError(errorType: e)
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
        } catch let e {
            handleError(errorType: e)
        }
        
        return device
    }
    
    func handleResult(result: OSStatus) throws {
        if result != kAudioHardwareNoError {
            NSLog("Error occurred in AudioController. RC: " + String(result))
            
            switch(result) {
            case kAudioHardwareBadDeviceError:
                throw AudioControllerError.AudioHardwareBadDevice
            case kAudioHardwareNotRunningError:
                throw AudioControllerError.AudioHardwareNotRunning
            case kAudioHardwareUnspecifiedError:
                throw AudioControllerError.AudioHardwareUnspecifiedError
            case kAudioHardwareUnknownPropertyError:
                throw AudioControllerError.AudioHardwareUnknownProperty
            case kAudioHardwareBadPropertySizeError:
                throw AudioControllerError.AudioHardwareBadPropertySize
            case kAudioHardwareIllegalOperationError:
                throw AudioControllerError.AudioHardwareIllegalOperation
            case kAudioHardwareBadObjectError:
                throw AudioControllerError.AudioHardwareBadObject
            case kAudioHardwareBadStreamError:
                throw AudioControllerError.AudioHardwareBadStream
            case kAudioHardwareUnsupportedOperationError:
                throw AudioControllerError.AudioHardwareUnsupportedOperation
            case kAudioDeviceUnsupportedFormatError:
                throw AudioControllerError.AudioDeviceUnsupportedFormat
            case kAudioDevicePermissionsError:
                throw AudioControllerError.AudioDevicePermissionsError
            default:
                throw AudioControllerError.AudioControllerUnknownError
            }
        }
    }

    func handleError(errorType: Error) {
        switch(errorType) {
        case AudioControllerError.AudioHardwareBadDevice:
            NSLog("AudioController: Bad Device")
        case AudioControllerError.AudioHardwareNotRunning:
            NSLog("AudioController: Audio Hardware Not Running")
        case AudioControllerError.AudioHardwareUnspecifiedError:
            NSLog("AudioController: Unspecified Error")
        case AudioControllerError.AudioHardwareBadPropertySize:
            NSLog("AudioController: Bad Property Size")
        case AudioControllerError.AudioHardwareIllegalOperation:
            NSLog("AudioController: Illegal Operation")
        case AudioControllerError.AudioHardwareBadObject:
            NSLog("AudioController: Bad Object")
        case AudioControllerError.AudioHardwareBadStream:
            NSLog("AudioController: Bad Stream")
        case AudioControllerError.AudioHardwareUnsupportedOperation:
            NSLog("AudioController: Unsupported Operation")
        case AudioControllerError.AudioDeviceUnsupportedFormat:
            NSLog("AudioController: Unsupported Format")
        case AudioControllerError.AudioDevicePermissionsError:
            NSLog("AudioController: Audio Device Permissions Error")
        case AudioControllerError.AudioHardwareUnknownProperty:
            NSLog("AudioController: Unknown Property")
        case AudioControllerError.AudioControllerUnknownError:
            NSLog("AudioController: Unknown Error Occurred")
        default:
            NSLog("AudioController: Unknown Error Occurred")
        }
    }
}
