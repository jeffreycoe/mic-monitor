//
//  AppDelegate.swift
//  Mic Monitor
//
//  Created by Jeffrey Coe on 10/22/16.
//  Copyright © 2016 Jeffrey Coe. All rights reserved.
//

import Cocoa

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {
    var statusBar = NSStatusBar.system()
    var statusBarItem : NSStatusItem = NSStatusItem()
    var itemMenu : NSMenu = NSMenu()
    var quitMenuItem : NSMenuItem = NSMenuItem(title: "Exit Mic Monitor", action: #selector(AppDelegate.quitApplication), keyEquivalent: "")
    var micStatusMenuItem : NSMenuItem = NSMenuItem(title: "Mic Status: Off", action: nil, keyEquivalent: "")
    var mic_on_image = NSImage(named: "mic_on")
    var mic_off_image = NSImage(named: "mic_off")
    var audioController = AudioController()

    func applicationDidFinishLaunching(_ aNotification: Notification) {
        buildStatusItemMenu()

        statusBarItem = statusBar.statusItem(withLength: NSSquareStatusItemLength)
        statusBarItem.menu = itemMenu
        statusBarItem.image = mic_off_image
        statusBarItem.highlightMode = true
    }

    func applicationWillTerminate(_ aNotification: Notification) {
        // Insert code here to tear down your application
    }
 
    func buildStatusItemMenu() {
        let separator = NSMenuItem.separator()
        
        itemMenu.addItem(micStatusMenuItem)
        itemMenu.addItem(separator)
        itemMenu.addItem(quitMenuItem)
    }
    
    func quitApplication() {
        NSApplication.shared().terminate(self)
    }
}

