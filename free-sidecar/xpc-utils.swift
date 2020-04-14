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
    
    let promise = Promise<NSXPCConnection>.pending()
    
    if let conn = S.xpcServiceConnection { // cached
        promise.fulfill(conn)
    } else {
        let conn = NSXPCConnection(serviceName: XPC_BUNDLE_ID)
        S.xpcServiceConnection = conn
        
        conn.remoteObjectInterface = NSXPCInterface(with: FreeSidecarXPCProtocol.self)
        conn.invalidationHandler = { () -> Void in
            conn.invalidationHandler = nil
            os_log(.debug, log: log, "XPC connection invalidated")
            S.xpcServiceConnection = nil
        }

        conn.resume()

        promise.fulfill(conn)
    }
    
    return promise
}

func xpcUpperCaseString(_ string: String) -> Promise<String> {
    let promise = Promise<String>.pending()
    
    if let conn = try? await(connectToXPCService()),
        let service = conn.remoteObjectProxyWithErrorHandler(promise.reject) as? FreeSidecarXPCProtocol {
        
        service.upperCaseString(string, withReply: promise.fulfill)
    } else {
        promise.reject(XPCUnavailableError())
    }
    
    return promise
}

func xpcInstallHelper() -> Promise<Void> {
    let promise = Promise<Void>.pending()
    
    if let conn = try? await(connectToXPCService()),
        let service = conn.remoteObjectProxyWithErrorHandler(promise.reject) as? FreeSidecarXPCProtocol {
        
        service.installHelper {
            if let error = $0 {
                promise.reject(error)
            } else {
                promise.fulfill(())
            }
        }
    } else {
        promise.reject(XPCUnavailableError())
    }
    
    return promise
}
