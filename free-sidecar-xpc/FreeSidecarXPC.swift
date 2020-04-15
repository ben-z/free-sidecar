//
//  free_sidecar_xpc.m
//  free-sidecar-xpc
//
//  Created by Ben Zhang on 2020-04-13.
//  Copyright © 2020 Ben Zhang. All rights reserved.
//

import Foundation
import os.log
import ServiceManagement

class FreeSidecarXPCDelegate: NSObject, NSXPCListenerDelegate, FreeSidecarXPCProtocol {
    private let service = NSXPCListener.service()
    private let authorization: Authorization? = try? Authorization()
    
    override init() {
        super.init()
        service.delegate = self

        os_log(.debug, log: log, "Authorization available?: %{public}s", String(authorization != nil))
        assert(authorization != nil) // crash during developemnt
    }

    func run() {
        service.resume() // never returns
        os_log(.error, log: log, "service.resume() returned!")
    }

    // MARK: -
    // MARK: NSXPCListenerDelegate protocol
    func listener(_ listener: NSXPCListener, shouldAcceptNewConnection newConnection: NSXPCConnection) -> Bool {
        newConnection.exportedInterface = NSXPCInterface(with: FreeSidecarXPCProtocol.self)
        newConnection.exportedObject = self
        newConnection.invalidationHandler = { () in
            os_log(.debug, log: log, "Connection invalidated!")
        }
        newConnection.resume()
        return true
    }

    // MARK: -
    // MARK: FreeSidecarXPCProtocol
    func upperCaseString(_ string: String, withReply reply: @escaping (String) -> Void) {
        os_log(.debug, log: log, "upperCaseString is called")
        let response = string.uppercased()
        reply(response)
    }

    func installHelper(withReply reply: @escaping (Error?) -> Void) {
        guard let auth = authorization else {
            reply(XPCError(.authUnavailable))
            return
        }

        do {
            try auth.authorizeRights(rights: [kSMRightBlessPrivilegedHelper], flags: [.interactionAllowed, .extendRights, .preAuthorize])
        } catch {
            os_log(.error, log: log, "Authorization error: %s", error.localizedDescription)
            reply(XPCError(.authUnavailable))
            return
        }

        var cfErr: Unmanaged<CFError>?

        if SMJobBless(kSMDomainSystemLaunchd, HELPER_BUNDLE_ID as CFString, auth.authRef, &cfErr) {
            reply(nil)
        } else if let err = cfErr?.takeRetainedValue() {
            reply(err)
        } else {
            reply(XPCError(.unknownError))
        }
    }
}
