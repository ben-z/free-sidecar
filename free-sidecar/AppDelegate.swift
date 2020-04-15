//
//  AppDelegate.swift
//  free-sidecar
//
//  Created by Ben Zhang on 2019-10-26.
//  Copyright © 2019 Ben Zhang. All rights reserved.
//

import Cocoa
import SwiftUI
import os.log
import free_sidecar_xpc

let log = OSLog(subsystem: (Bundle.main.bundleIdentifier ?? "bundle") + ".app", category: "default")

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {

    var window: NSWindow!


    func applicationDidFinishLaunching(_ aNotification: Notification) {
        xpcUpperCaseAndJoinStrings("abc", "DeF").then { response in
            os_log("Response from XPC service: %{public}s", log: log, response)
        }.catch { error in
            os_log(.error, log: log, "XPC Error: %{public}s", error.localizedDescription)
        }
        
        xpcUpdateHelper().then {_ in
            os_log(.info, log: log, "Successfully installed helper")
        }.catch { error in
            os_log(.error, log: log, "An error occured when installing helper: %s", error.localizedDescription)
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

