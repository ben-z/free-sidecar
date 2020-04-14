//
//  AppDelegate.swift
//  free-sidecar
//
//  Created by Ben Zhang on 2019-10-26.
//  Copyright © 2019 Ben Zhang. All rights reserved.
//

import Cocoa
import SwiftUI

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {

    var window: NSWindow!


    func applicationDidFinishLaunching(_ aNotification: Notification) {
        xpcUpperCaseString("abc").then { response in
            print("Response from XPC service:", response)
        }.catch { error in
            print("XPC Error", error)
        }
        
        // Create the SwiftUI view that provides the window contents.
        let contentView = ContentView()

        // Create the window and set the content view. 
        window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 480, height: 700),
            styleMask: [.titled, .closable, .miniaturizable, .resizable, .fullSizeContentView],
            backing: .buffered, defer: false)
        window.center()
        window.setFrameAutosaveName("Main Window")
        window.contentView = NSHostingView(rootView: contentView)
        window.makeKeyAndOrderFront(nil)

//        print(Bundle.main.url(forResource: "compatibility", withExtension: "json", subdirectory: "compatibility"))
    }

    func applicationWillTerminate(_ aNotification: Notification) {
        // Insert code here to tear down your application
    }


}

