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

class XPCClient<P>  {
    enum InitParams {
        case service(_ serviceName: String)
        case machService(_ machServiceName: String, _ options: NSXPCConnection.Options)
    }

    let initParams: InitParams
    var connection: NSXPCConnection?

    // This is a hack to conform with Protocol in the NSXPCInterface call. Source:
    //   https://stackoverflow.com/questions/47743519/swift-generics-constrain-type-parameter-to-protocol#comment82489181_47743519
    //   https://gist.github.com/hamishknight/f90858a2bb2694fbcfc3bceb429109c4
    private let toProtocol: (P.Type) -> Protocol

    init(serviceName: String, toProtocol: @escaping (P.Type) -> Protocol) {
        initParams = .service(serviceName)
        self.toProtocol = toProtocol
    }

    init(machServiceName: String, options: NSXPCConnection.Options, toProtocol: @escaping (P.Type) -> Protocol) {
        initParams = .machService(machServiceName, options)
        self.toProtocol = toProtocol

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

        conn.remoteObjectInterface = NSXPCInterface(with: toProtocol(P.self))
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
    @available(*, deprecated, message: "Use call(getMethod:param:) instead")
    func call<T>(withReply attachReply: (Any, @escaping (T) -> Void) -> Void?) -> Promise<T> {
        let promise = Promise<T>.pending()

        let service = connect().remoteObjectProxyWithErrorHandler(promise.reject)

        if attachReply(service, promise.fulfill) == nil {
            os_log(.error, log: log, "service is nil")
            promise.reject(XPCUnavailableError())
        }

        return promise
    }

    /// Calls a method on the remote proxy
    ///
    /// This example calls the upperCaseString function on the XPC protocol.
    ///
    ///     xpcClient.callMethod({ $0.upperCaseString }, string)
    ///
    /// - Parameter getMethod: A closure `{ service in ... }` . You should return the method to call from the closure.
    /// - Returns: A `Promise` that resolves to the calling arguments of `reply`
    ///
    /// - Note: When the callback has a single Error argument, the promise is rejected instead of fulfilled: https://github.com/google/promises/issues/140
    func call<A, R>(_ getMethod: (P) -> (A, @escaping (R) -> Void) -> Void, _ param: A) -> Promise<R> {
        let promise = Promise<R>.pending()
        if let service = connect().remoteObjectProxyWithErrorHandler(promise.reject) as? P {
            getMethod(service)(param, promise.fulfill)
        } else {
            promise.reject(XPCUnavailableError())
        }
        return promise
    }

    /// A version of `call(getMethod:param:)` with 0 arguments
    func call<R>(_ getMethod: (P) -> (@escaping (R) -> Void) -> Void) -> Promise<R> {
        let promise = Promise<R>.pending()
        if let service = connect().remoteObjectProxyWithErrorHandler(promise.reject) as? P {
            getMethod(service)(promise.fulfill)
        } else {
            promise.reject(XPCUnavailableError())
        }
        return promise
    }

    /// A version of `call(getMethod:param:) `with 2 arguments
    func call<A, B, R>(_ getMethod: (P) -> (A, B, @escaping (R) -> Void) -> Void, _ paramA: A, _ paramB: B) -> Promise<R> {
        let promise = Promise<R>.pending()
        if let service = connect().remoteObjectProxyWithErrorHandler(promise.reject) as? P {
            getMethod(service)(paramA, paramB, promise.fulfill)
        } else {
            promise.reject(XPCUnavailableError())
        }
        return promise
    }
}
