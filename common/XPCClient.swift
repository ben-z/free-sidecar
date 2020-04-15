//
//  XPCClient.swift
//  free-sidecar
//
//  Created by Ben Zhang on 2020-04-14.
//  Copyright © 2020 Ben Zhang. All rights reserved.
//

import Foundation
import Promises
import os.log


struct XPCUnavailableError: Error {}

class XPCClient<P: Protocol> {
    enum InitParams {
        case service(_ serviceName: String)
        case machService(_ machServiceName: String, _ options: NSXPCConnection.Options)
    }

    let initParams: InitParams
    let serviceProtocol: P
    var connection: NSXPCConnection?

    init(serviceName: String, protocol serviceProtocol: P) {
        initParams = .service(serviceName)
        self.serviceProtocol = serviceProtocol
    }

    init(machServiceName: String, options: NSXPCConnection.Options, protocol serviceProtocol: P) {
        initParams = .machService(machServiceName, options)
        self.serviceProtocol = serviceProtocol
    }

    func connect() -> NSXPCConnection {
        if let conn = self.connection {
            return conn
        }

        let conn: NSXPCConnection
        switch initParams {
        case let .service(serviceName):
            conn = NSXPCConnection(serviceName: serviceName)
        case let .machService(machServiceName, options):
            conn = NSXPCConnection(machServiceName: machServiceName, options: options)
        }
        self.connection = conn


        conn.remoteObjectInterface = NSXPCInterface(with: serviceProtocol.self)
        conn.invalidationHandler = { () -> Void in
            conn.invalidationHandler = nil
            os_log(.debug, log: log, "XPC connection to %{public}s invalidated", conn.serviceName ?? "<unavailable>")
            self.connection = nil
        }

        conn.resume()

        return conn
    }

    /// Calls a method on the remote proxy
    ///
    /// This example calls the upperCaseString function on the XPC protocol.
    ///
    ///     xpcClient.call { service, reply in (service as? FreeSidecarXPCProtocol)?.upperCaseString(string, withReply: reply) }
    ///
    /// - Parameter withReply: A closure `{ service, reply in ... }` . You should cast `service` to the protocol type and
    ///   call the proxy function with `reply` as the callback.
    /// - Returns: A `Promise` that resolves to the calling arguments of `reply`
    ///
    /// - Note: This still requires a manual type cast and some ugly-looking syntax because I couldn't find a way to make the generics work
    func call<T>(withReply attachReply: (Any, @escaping (T) -> Void) -> Void?) -> Promise<T> {
        let promise = Promise<T>.pending()

        let service = connect().remoteObjectProxyWithErrorHandler(promise.reject)

        if attachReply(service, promise.fulfill) == nil {
            os_log(.error, log: log, "service is nil")
            promise.reject(XPCUnavailableError())
        }

        return promise
    }
}
