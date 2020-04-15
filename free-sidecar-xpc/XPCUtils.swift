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

private let xpcClient = XPCClient<FreeSidecarHelperProtocol>(machServiceName: HELPER_BUNDLE_ID, options: .privileged, toProtocol: {$0 })

func xpcLowerCaseString(_ string: String) -> Promise<String> {
    xpcClient.call({ $0.lowerCaseString }, string)
}

func xpcGetBuildNumber() -> Promise<String?> {
    xpcClient.call({ $0.getBuildNumber })
}
