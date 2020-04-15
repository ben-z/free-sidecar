//
//  FreeSidecarHelper.swift
//  free-sidecar-helper
//
//  Created by Ben Zhang on 2020-04-14.
//  Copyright © 2020 Ben Zhang. All rights reserved.
//

import Foundation
import os.log
import ServiceManagement

class FreeSidecarHelperDelegate: NSObject, NSXPCListenerDelegate, FreeSidecarHelperProtocol {
    private let service = NSXPCListener(machServiceName: HELPER_BUNDLE_ID)
//    private let authorization: Authorization? = try? Authorization()
    private var helperToolConnection: NSXPCConnection?

    override init() {
        super.init()
        service.delegate = self

//        os_log(.debug, log: log, "Authorization available?: %{public}s", String(authorization != nil))
//        assert(authorization != nil) // crash during developemnt
    }

    func run() {
        os_log(.info, log: log, "running!")
        service.resume()

        RunLoop.current.run()
    }

    // MARK: -
    // MARK: NSXPCListenerDelegate protocol
    func listener(_ listener: NSXPCListener, shouldAcceptNewConnection newConnection: NSXPCConnection) -> Bool {
        os_log(.debug, log: log, "listener is called!")
        newConnection.exportedInterface = NSXPCInterface(with: FreeSidecarHelperProtocol.self)
        newConnection.exportedObject = self
        newConnection.invalidationHandler = { () in
            os_log(.debug, log: log, "Connection invalidated!")
            // TODO: Count active connections and stop helper if possible
        }
        newConnection.resume()
        return true
    }

    // MARK: -
    // MARK: FreeSidecarHelperProtocol
    func lowerCaseString(_ string: String, withReply reply: @escaping (String) -> Void) {
        os_log(.debug, log: log, "lowerCaseString is called")
        let response = string.lowercased()
        reply(response)
    }

    func getBuildNumber(withReply reply: @escaping (String?) -> Void) {
        let build = Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String
        os_log(.debug, log: log, "Returning build number: %{public}s", build ?? "[unavailable]")
        reply(build)
    }
}
