//
//  XPCUtils.swift
//  free-sidecar-xpc
//
//  Created by Ben Zhang on 2020-04-15.
//  Copyright © 2020 Ben Zhang. All rights reserved.
//

import Foundation
import free_sidecar_helper
import Promises
import os.log

private typealias XPCProtocol = FreeSidecarHelperProtocol

private let xpcClient = XPCClient(machServiceName: HELPER_BUNDLE_ID, options: .privileged, protocol: XPCProtocol.self)

func xpcLowerCaseString(_ string: String) -> Promise<String> {
    xpcClient.call { service, reply in (service as? XPCProtocol)?.lowerCaseString(string, withReply: reply) }
}
