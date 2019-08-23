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
    var statusBar = NSStatusBar.system
    var statusBarItem : NSStatusItem = NSStatusItem()
    var micOnImage = NSImage(named: "mic_on")
    var micOffImage = NSImage(named: "mic_off")
    var audioController = AudioController()
    let itemMenu : NSMenu = NSMenu()
    var activeDevices: [AudioDeviceID] = []
    var inputDevices: [AudioDeviceID] = []
    
    typealias AudioDeviceListenerCallback = @convention(c) (UInt32, UInt32, UnsafePointer<AudioObjectPropertyAddress>, UnsafeMutableRawPointer?) -> Int32

    func applicationDidFinishLaunching(_ aNotification: Notification) {
        statusBarItem = statusBar.statusItem(withLength: NSStatusItem.squareLength)
        statusBarItem.menu = itemMenu
        statusBarItem.image = micOffImage
        statusBarItem.highlightMode = true
        
        audioController.addAudioHardwareDeviceNotificationListener(callback: deviceNotificationCallback)
        inputDevices = audioController.getAudioInputDevices()
        
        for device in inputDevices {
            if audioController.isAudioDeviceInUseSomewhere(device: device) {
                statusBarItem.image = micOnImage
                activeDevices.append(device)
            }
            
            audioController.addAudioDeviceInUseSomewhereListener(device: device, callback: deviceInUseSomewhereCallback)
        }
        
        buildStatusItemMenu()
    }
    
    public let deviceInUseSomewhereCallback: AudioDeviceListenerCallback = {
        (device: UInt32, numOfAddresses: UInt32, addresses: UnsafePointer<AudioObjectPropertyAddress>, data: UnsafeMutableRawPointer?) -> Int32 in
        
        var audioController = AudioController()
        let appDelegate = AppDelegate.getDelegate()
        
        if audioController.isAudioDeviceInUseSomewhere(device: device) {
            NSLog("Device " + audioController.getAudioDeviceName(device: device) + " is in use!")
            appDelegate.changeMicStatus(isMicOn: true, device: device)
        } else {
            NSLog("Device " + audioController.getAudioDeviceName(device: device) + " is NOT in use!")
            appDelegate.changeMicStatus(isMicOn: false, device: device)
        }
        
        return 0
    }

    public let deviceNotificationCallback: AudioDeviceListenerCallback = {
        (device: UInt32, numOfAddresses: UInt32, addresses: UnsafePointer<AudioObjectPropertyAddress>, data: UnsafeMutableRawPointer?) -> Int32 in
        
        var audioController = AudioController()
        let appDelegate = AppDelegate.getDelegate()
        
        appDelegate.buildStatusItemMenu()
        
        for device in audioController.getAudioInputDevices() {
            if !appDelegate.inputDevices.contains(device) {
                audioController.addAudioDeviceInUseSomewhereListener(device: device, callback: appDelegate.deviceInUseSomewhereCallback)
            }
        }
        
        appDelegate.inputDevices = audioController.getAudioInputDevices()
        
        return 0
    }
    
    func applicationWillTerminate(_ aNotification: Notification) {
        
    }
 
    func buildStatusItemMenu() {
        itemMenu.removeAllItems()
        
        let micStatusMenuItem : NSMenuItem = NSMenuItem(title: "Mic Status: Off", action: nil, keyEquivalent: "")
        let deviceListMenuItem : NSMenuItem = NSMenuItem(title: "Input Devices:", action: nil, keyEquivalent: "")
        let quitMenuItem: NSMenuItem = NSMenuItem(title: "Exit Mic Monitor", action: #selector(AppDelegate.quitApplication), keyEquivalent: "")
        let activeDeviceListMenuItem: NSMenuItem = NSMenuItem(title: "Active Devices:", action: nil, keyEquivalent: "")
        let devices = audioController.getAudioInputDevices()
        let deviceMenuItems = getDeviceMenuItems(devices: devices)
        var activeDeviceMenuItems: [NSMenuItem] = []
        
        if activeDevices.count != 0 {
            micStatusMenuItem.title = "Mic Status: On"
            activeDeviceMenuItems = getDeviceMenuItems(devices: activeDevices)
        } else {
            micStatusMenuItem.title = "Mic Status: Off"

            let noActiveDeviceMenuItem: NSMenuItem = NSMenuItem(title: "(none)", action: nil, keyEquivalent: "")
            noActiveDeviceMenuItem.indentationLevel = 1
            
            activeDeviceMenuItems.append(noActiveDeviceMenuItem)
        }
        
        itemMenu.addItem(micStatusMenuItem)
        itemMenu.addItem(NSMenuItem.separator())
        itemMenu.addItem(activeDeviceListMenuItem)
        
        for menuItem in activeDeviceMenuItems  {
            itemMenu.addItem(menuItem)
        }
        
        itemMenu.addItem(NSMenuItem.separator())
        itemMenu.addItem(deviceListMenuItem)
        
        for menuItem in deviceMenuItems  {
            itemMenu.addItem(menuItem)
        }
        
        itemMenu.addItem(NSMenuItem.separator())
        itemMenu.addItem(quitMenuItem)
    }
    
    @objc func quitApplication() {
        NSApplication.shared.terminate(self)
    }
    
    class func getDelegate() -> AppDelegate {
        return NSApplication.shared.delegate as! AppDelegate
    }
    
    func getDeviceMenuItems(devices: [AudioDeviceID]) -> [NSMenuItem] {
        var menuItems: [NSMenuItem] = []
        
        for device in devices {
            let menuItem = NSMenuItem(title: audioController.getAudioDeviceName(device: device), action: nil, keyEquivalent: "")
            
            menuItem.indentationLevel = 1
            menuItems.append(menuItem)
        }
        
        return menuItems
    }
    
    func changeMicStatus(isMicOn: Bool, device: AudioDeviceID) {
        if isMicOn {
            activeDevices.append(device)
            buildStatusItemMenu()
        } else {
            activeDevices = activeDevices.filter{$0 != device}
            buildStatusItemMenu()
        }
        
        if activeDevices.count != 0 {
            statusBarItem.image = micOnImage
        } else {
            statusBarItem.image = micOffImage
        }
    }
}

