//
//  xpc-utils.swift
//  free-sidecar
//
//  Created by Ben Zhang on 2020-04-13.
//  Copyright © 2020 Ben Zhang. All rights reserved.
//

import Foundation
import free_sidecar_xpc
import Promises
import os.log


struct XPCUnavailableError: Error {}

func connectToXPCService() -> Promise<NSXPCConnection> {
    struct S {
        static var xpcServiceConnection: NSXPCConnection?
    }

    return Promise<NSXPCConnection> { fulfill, reject in
        if S.xpcServiceConnection == nil {
            S.xpcServiceConnection = NSXPCConnection(serviceName: "ben-z.free-sidecar-xpc")
        }

        guard let conn = S.xpcServiceConnection else {
            reject(XPCUnavailableError())
            return
        }

        conn.remoteObjectInterface = NSXPCInterface(with: FreeSidecarXPCProtocol.self)
        conn.invalidationHandler = { () -> Void in
            conn.invalidationHandler = nil
            os_log(.debug, log: log, "XPC connection invalidated")
            OperationQueue.main.addOperation {
                S.xpcServiceConnection = nil
            }
        }

        conn.resume()

        fulfill(conn)
    }
}

func xpcUpperCaseString(_ string: String) -> Promise<String> {
    return Promise<String> { fulfill, reject in
        connectToXPCService().then { conn in
            guard let service = conn.remoteObjectProxyWithErrorHandler(reject) as? FreeSidecarXPCProtocol else {
                reject(XPCUnavailableError())
                return
            }

            service.upperCaseString(string, withReply: fulfill)
        }.catch(reject)
    }
}
