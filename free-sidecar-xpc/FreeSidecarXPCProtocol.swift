//
//  free_sidecar_xpcProtocol.h
//  free-sidecar-xpc
//
//  Created by Ben Zhang on 2020-04-13.
//  Copyright © 2020 Ben Zhang. All rights reserved.
//

import Foundation

public let XPCbundleIdentifier = "1232123"

@objc public protocol FreeSidecarXPCProtocol {
    func upperCaseString(_ string: String, withReply reply: @escaping (String) -> Void)
}
