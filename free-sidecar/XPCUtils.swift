//
//  XPCUtils.swift
//  free-sidecar
//
//  Created by Ben Zhang on 2020-04-14.
//  Copyright © 2020 Ben Zhang. All rights reserved.
//

import Foundation
import free_sidecar_xpc
import Promises
import os.log

private let xpcClient = XPCClient(serviceName: XPC_BUNDLE_ID, protocol: FreeSidecarXPCProtocol.self)

func xpcUpperCaseString(_ string: String) -> Promise<String> {
    xpcClient.call { service, reply in (service as? FreeSidecarXPCProtocol)?.upperCaseString(string, withReply: reply) }
}

func xpcInstallHelper() -> Promise<Void> {
    xpcClient.call { service, reply in (service as? FreeSidecarXPCProtocol)?.installHelper(withReply: reply) }.then {
        if let error = $0 {
            return Promise<Void> { throw error }
        } else {
            return Promise<Void> { resolve, reject in resolve(()) }
        }
    }
}

