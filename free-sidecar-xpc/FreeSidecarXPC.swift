//
//  free_sidecar_xpc.h
//  free-sidecar-xpc
//
//  Created by Ben Zhang on 2020-04-13.
//  Copyright © 2020 Ben Zhang. All rights reserved.
//

import Foundation
import os.log

class FreeSidecarXPC: NSObject, FreeSidecarXPCProtocol {
    func upperCaseString(_ string: String, withReply reply: @escaping (String) -> Void) {
        os_log(.debug, log: log, "upperCaseString is called")
        let response = string.uppercased()
        reply(response)
    }
}
