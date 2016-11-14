//
//  AppDelegate.swift
//  Mic Monitor
//
//  Created by Jeffrey Coe on 10/22/16.
//  Copyright © 2016 Jeffrey Coe. All rights reserved.
//

import Cocoa
import CoreAudio
import AudioToolbox

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {
    var statusBar = NSStatusBar.system()
    var statusBarItem : NSStatusItem = NSStatusItem()
    var itemMenu : NSMenu = NSMenu()
    var quitMenuItem : NSMenuItem = NSMenuItem(title: "Exit Mic Monitor", action: #selector(AppDelegate.quitApplication), keyEquivalent: "")
    var micStatusMenuItem : NSMenuItem = NSMenuItem(title: "Mic Status: Off", action: nil, keyEquivalent: "")
    var deviceListMenuItem : NSMenuItem = NSMenuItem(title: "Device: (None)", action: nil, keyEquivalent: "")
    var micOnImage = NSImage(named: "mic_on")
    var micOffImage = NSImage(named: "mic_off")
    var audioController = AudioController()
    typealias AudioDeviceCallback = @convention(c) (UInt32, UInt32, UnsafePointer<AudioObjectPropertyAddress>, UnsafeMutableRawPointer?) -> Int32

    func applicationDidFinishLaunching(_ aNotification: Notification) {
        buildStatusItemMenu()

        statusBarItem = statusBar.statusItem(withLength: NSSquareStatusItemLength)
        statusBarItem.menu = itemMenu
        statusBarItem.image = micOffImage
        statusBarItem.highlightMode = true
        
        let devices = audioController.getAudioInputDevices()
        
        for device in devices {
            audioController.addAudioDeviceInUseSomewhereListener(device: device, proc: deviceInUseSomewhereCallback)
        }
    }
    
    public let deviceInUseSomewhereCallback: AudioDeviceCallback = { (device: UInt32, numOfAddresses: UInt32, addresses: UnsafePointer<AudioObjectPropertyAddress>, data: UnsafeMutableRawPointer?) -> Int32 in
        
        var audioController = AudioController()
        let appDelegate = AppDelegate.getDelegate()
        
        if audioController.isAudioDeviceInUseSomewhere(device: device) {
            NSLog("Device " + audioController.getAudioDeviceName(device: device) + " is in use!")
            appDelegate.changeMicStatus(isMicOn: true, device: audioController.getAudioDeviceName(device: device))
        } else {
            NSLog("Device " + audioController.getAudioDeviceName(device: device) + " is NOT in use!")
            appDelegate.changeMicStatus(isMicOn: false)
        }
        
        return 0
    }

    func applicationWillTerminate(_ aNotification: Notification) {
        
    }
 
    func buildStatusItemMenu() {
        let separator = NSMenuItem.separator()
        
        itemMenu.addItem(micStatusMenuItem)
        itemMenu.addItem(deviceListMenuItem)
        itemMenu.addItem(separator)
        itemMenu.addItem(quitMenuItem)
    }
    
    func quitApplication() {
        NSApplication.shared().terminate(self)
    }
    
    class func getDelegate() -> AppDelegate {
        return NSApplication.shared().delegate as! AppDelegate
    }
    
    public func changeMicStatus(isMicOn: Bool, device: String = "") {
        if isMicOn {
            statusBarItem.image = micOnImage
            micStatusMenuItem.title = "Mic Status: On"
            deviceListMenuItem.title = "Device: " + device
        } else {
            statusBarItem.image = micOffImage
            micStatusMenuItem.title = "Mic Status: Off"
            deviceListMenuItem.title = "Device: (None)"
        }
    }
}

