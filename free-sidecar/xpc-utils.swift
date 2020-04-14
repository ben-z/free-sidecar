//
//  xpc-utils.swift
//  free-sidecar
//
//  Created by Ben Zhang on 2020-04-13.
//  Copyright © 2020 Ben Zhang. All rights reserved.
//

import Foundation
import free_sidecar_xpc

private var xpcServiceConnection: NSXPCConnection?

func connectToXPCService() -> Bool {
    if xpcServiceConnection == nil {
        xpcServiceConnection = NSXPCConnection(serviceName: "ben-z.free-sidecar-xpc")
        xpcServiceConnection?.remoteObjectInterface = NSXPCInterface(with: FreeSidecarXPCProtocol.self)
        xpcServiceConnection?.invalidationHandler = { () -> Void in
            xpcServiceConnection?.invalidationHandler = nil
            print("XPC connection invalidated")
            OperationQueue.main.addOperation {
                xpcServiceConnection = nil
            }
        }
        
        xpcServiceConnection?.resume()
    }
    
    return xpcServiceConnection != nil
}

func xpcUpperCaseString(_ string: String, withReply reply: @escaping (String) -> Void) {
    guard connectToXPCService() else {
        return
    }
    let service = xpcServiceConnection?.remoteObjectProxyWithErrorHandler { error in
        print("Received error:", error)
    } as? FreeSidecarXPCProtocol
    service?.upperCaseString(string, withReply: reply)
}
