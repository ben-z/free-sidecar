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

private let xpcClient = XPCClient<FreeSidecarXPCProtocol>(serviceName: XPC_BUNDLE_ID, toProtocol: { $0 })

func xpcUpperCaseString(_ string: String) -> Promise<String> {
    xpcClient.call({ $0.upperCaseString }, string)
}

func xpcUpperCaseAndJoinStrings(_ string1: String, _ string2: String) -> Promise<String> {
    xpcClient.call({ $0.upperCaseAndJoinStrings }, string1, string2)
}

func xpcInstallHelper() -> Promise<Void> {
    xpcClient.call({ $0.installHelper })
}

func xpcUpdateHelper() -> Promise<Void> {
    xpcClient.call({ $0.updateHelper })
}

func xpcGetHelperEndpoint() -> Promise<(Error?, NSXPCListenerEndpoint?, NSData?)> {
    xpcClient.call({ $0.getHelperEndpoint })
}
