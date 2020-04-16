//
//  FreeSidecarXPC.swift
//  free-sidecar-xpc
//
//  Created by Ben Zhang on 2020-04-13.
//  Copyright © 2020 Ben Zhang. All rights reserved.
//

import Foundation
import os.log
import ServiceManagement
import free_sidecar_helper

class FreeSidecarXPCDelegate: NSObject, NSXPCListenerDelegate, FreeSidecarXPCProtocol {
    private let service = NSXPCListener.service()
    private let authorization: Authorization? = try? Authorization()
    private var helperToolConnection: NSXPCConnection?
    
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

    func upperCaseAndJoinStrings(_ string1: String, _ string2: String, withReply reply: @escaping (String) -> Void) {
        os_log(.debug, log: log, "upperCaseAndJoinStringsis called")
        let response = (string1 + string2).uppercased()
        reply(response)
    }

    func installHelper(withReply reply: @escaping (Error?) -> Void) {
        guard let auth = authorization else {
            reply(XPCServiceError(.authUnavailable))
            return
        }

        do {
            try auth.authorizeRights(rights: [kSMRightBlessPrivilegedHelper], flags: [.interactionAllowed, .extendRights, .preAuthorize])
        } catch {
            os_log(.error, log: log, "Authorization error: %s", error.localizedDescription)
            reply(XPCServiceError(.authUnavailable))
            return
        }

        var cfErr: Unmanaged<CFError>?

        if SMJobBless(kSMDomainSystemLaunchd, HELPER_BUNDLE_ID as CFString, auth.authRef, &cfErr) {
            reply(nil)
        } else if let err = cfErr?.takeRetainedValue() {
            reply(err)
        } else {
            reply(XPCServiceError(.unknownError))
        }
    }

    func updateHelper(withReply reply: @escaping (Error?) -> Void) {
        xpcGetBuildNumber().then {
            if let buildNumber = $0, buildNumber == HELPER_BUILD_NUMBER {
                os_log(.debug, log: log, "Helper is up-to-date (build %{public}s).", buildNumber)
                reply(nil)
            } else {
                os_log(.debug, log: log, "Helper version mismatch: expecting %{public}s, got %{public}s. Reinstalling helper.", HELPER_BUILD_NUMBER, $0 ?? "nil")
                self.installHelper(withReply: reply)
            }
        }.catch { error in
            os_log(.error, log: log, "Error getting build number: %s. Installing helper", error.localizedDescription)
            self.installHelper(withReply: reply)
        }
    }

    func getHelperToolConnection(withReply reply: @escaping (NSXPCListenerEndpoint) -> Void) {
        os_log(.debug, "Calling Helper")

        xpcLowerCaseString("AbCdE").then { response in
            os_log("Response from Helper service: %{public}s", log: log, response)
        }.catch { error in
            os_log(.error, log: log, "Helper XPC Error: %{public}s", error.localizedDescription)
        }

        xpcGetBuildNumber().then {
            if let buildNumber = $0 {
                os_log(.debug, log: log, "Got build number from helper: %{public}s", buildNumber)
            } else {
                os_log(.debug, log: log, "Unable to get build number from helper")
            }
        }.catch { error in
            os_log(.error, log: log, "Error when getting build number from helper: %{public}s %{public}s", String(describing: type(of: error)), error.localizedDescription)
        }

        // TODO reply
    }

    func getHelperEndpoint(withReply reply: @escaping (Error?, NSXPCListenerEndpoint?, NSData?) -> Void) {
        guard let auth = self.authorization else {
            os_log(.error, log: log, "XPC is unable to get helper endpoint because authorization is unavailable")
            reply(XPCServiceError(.authUnavailable), nil, nil)
            return
        }

        xpcGetEndpoint().then{ endpoint in
            var extForm = try auth.makeExternalForm()
            let data = NSData(bytes: &extForm, length: kAuthorizationExternalFormLength)
            reply(nil, endpoint, data)
            os_log(.error, log: log, "done returning helper endpoint")
        }.catch { error in
            os_log(.error, log: log, "XPC is Unable to get helper endpoint: %{public}s", error.localizedDescription)
            print(type(of: error))
        }
    }
}
