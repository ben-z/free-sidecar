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
//    private let authState = AuthorizationState()
    
    override init() {
        super.init()
        service.delegate = self
        
        let authAvailable = isAuthorizationAvailable()
        os_log(.debug, log: log, "isAuthorizationAvailable: %{public}s", String(authAvailable))
        assert(authAvailable) // crash during developemnt
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
        withExtendedLifetime(Authorization(
            rights: [kSMRightBlessPrivilegedHelper],
            flags: [.interactionAllowed, .extendRights, .preAuthorize]))
        { authorization in
            guard let ref = authorization.authRef else {
                os_log(.error, log: log, "Authorization error: %s", authorization.err!.localizedDescription)
                reply(XPCError(.authUnavailable))
                return
            }
            
            var cfErr: Unmanaged<CFError>?
    
            if SMJobBless(kSMDomainSystemLaunchd, HELPER_BUNDLE_ID as CFString, ref, &cfErr) {
                reply(nil)
            } else if let err = cfErr?.takeRetainedValue() {
                reply(err)
            } else {
                reply(XPCError(.unknownError))
            }
        }
    }
}
