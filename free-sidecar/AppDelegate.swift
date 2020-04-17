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
import free_sidecar_helper
import Promises

let log = OSLog(subsystem: (Bundle.main.bundleIdentifier ?? "bundle") + ".app", category: "default")

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {

    var window: NSWindow!

    func applicationDidFinishLaunching(_ aNotification: Notification) {
        do {
            let response = try await(xpcUpperCaseAndJoinStrings("abc", "DeF"))
            os_log("Response from XPC service: %{public}s", log: log, response)
        } catch {
            os_log(.error, log: log, "XPC Error: %{public}s", error.localizedDescription)
        }

        do {
            try await(xpcUpdateHelper())
            os_log(.info, log: log, "Helper is up-to-date.")
        } catch {
            os_log(.error, log: log, "An error occured when installing helper: %s", error.localizedDescription)
        }

        let response: (Error?, NSXPCListenerEndpoint?, NSData?)
        let helperEndpoint: NSXPCListenerEndpoint
        let authExtFormData: NSData
        do {
            os_log(.debug, log: log, "Getting helper endpoint")
            response = try await(xpcGetHelperEndpoint())
            if let error = response.0 {
                throw error
            }
            guard let _helperEndpoint = response.1, let _authExtFormData = response.2 else {
                    throw XPCInconsistentError()
            }
            helperEndpoint = _helperEndpoint
            authExtFormData = _authExtFormData
        } catch {
            os_log(.error, log: log, "An error occured when getting helper endpoint: %s", error.localizedDescription)
            return
        }

        os_log(.debug, log: log, "Connecting to helper")
        let helperConnection = XPCClient<FreeSidecarHelperProtocol>(listenerEndpoint: helperEndpoint, toProtocol: { $0 })

        do {
            if let buildNumber = try await(helperConnection.call({ $0.getBuildNumber })) {
                os_log(.debug, log: log, "[App] Got build number from helper: %{public}s", buildNumber)
            } else {
                os_log(.debug, log: log, "[App] Unable to get build number from helper")
            }
        } catch {
            os_log(.error, log: log, "[App] Error when getting build number from helper: %{public}s %{public}s", String(describing: type(of: error)), error.localizedDescription)
        }

        // Create the SwiftUI view that provides the window contents.
        let contentView = ContentView(helperConnection: helperConnection, authExtFormData: authExtFormData)

        // Create the window and set the content view.
        self.window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 480, height: 700),
            styleMask: [.titled, .closable, .miniaturizable, .resizable, .fullSizeContentView],
            backing: .buffered, defer: false)
        self.window.center()
        self.window.setFrameAutosaveName("Main Window")
        self.window.contentView = NSHostingView(rootView: contentView)
        self.window.makeKeyAndOrderFront(nil)


//        print(Bundle.main.url(forResource: "compatibility", withExtension: "json", subdirectory: "compatibility"))
    }

    func applicationWillTerminate(_ aNotification: Notification) {
        // Insert code here to tear down your application
    }


}

