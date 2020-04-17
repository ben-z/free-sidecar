//
//  FreeSidecarHelper.swift
//  free-sidecar-helper
//
//  Created by Ben Zhang on 2020-04-14.
//  Copyright © 2020 Ben Zhang. All rights reserved.
//

import Foundation
import os.log
import ServiceManagement

class FreeSidecarHelperDelegate: NSObject, NSXPCListenerDelegate, FreeSidecarHelperProtocol {
    private let service = NSXPCListener(machServiceName: HELPER_BUNDLE_ID)
//    private let authorization: Authorization? = try? Authorization()
    private var helperToolConnection: NSXPCConnection?

    override init() {
        super.init()
        service.delegate = self

//        os_log(.debug, log: log, "Authorization available?: %{public}s", String(authorization != nil))
//        assert(authorization != nil) // crash during developemnt
    }

    func run() {
        os_log(.info, log: log, "running!")
        service.resume()

        RunLoop.current.run()
    }

    // MARK: -
    // MARK: NSXPCListenerDelegate protocol
    func listener(_ listener: NSXPCListener, shouldAcceptNewConnection newConnection: NSXPCConnection) -> Bool {
        os_log(.debug, log: log, "listener is called!")
        newConnection.exportedInterface = NSXPCInterface(with: FreeSidecarHelperProtocol.self)
        newConnection.exportedObject = self
        newConnection.invalidationHandler = { () in
            os_log(.debug, log: log, "Connection invalidated!")
            // TODO: Count active connections and stop helper if possible
        }
        newConnection.resume()
        return true
    }

    // MARK: -
    // MARK: FreeSidecarHelperProtocol
    func getBuildNumber(withReply reply: @escaping (String?) -> Void) {
        let build = Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String
        os_log(.debug, log: log, "Returning build number: %{public}s", build ?? "[unavailable]")
        reply(build)
    }

    func getEndpoint(withReply reply: @escaping (NSXPCListenerEndpoint) -> Void) {
        reply(service.endpoint)
    }

    func mountRootAsRW(withReply reply: @escaping (Error?) -> Void) {
        let task = Process()
        let errorPipe = Pipe()

        task.executableURL = URL(fileURLWithPath: "/sbin/mount")
        task.arguments = ["-uw", "/"]
        task.standardError = errorPipe

        do {
            try task.run()
        } catch {
            // task launched unsuccessfully
            os_log(.error, log: log, "mount task launched unsuccessfully: %{public}s", error.localizedDescription)
            reply(error)
            return
        }

        task.waitUntilExit()
        if task.terminationStatus != 0 {
            let errorMsg = readToEOF(pipe: errorPipe)
            os_log(.error, log: log, "mount finished unsuccessfully: %{public}s", errorMsg)
            reply(HelperError(.commandError, dueTo: errorMsg))
        } else {
            os_log(.debug, log: log, "mounted")
            reply(nil)
        }
    }
    func setNVRAMBootFlag(withReply reply: @escaping (Error?) -> Void) {
        let task = Process()
        let errorPipe = Pipe()

        task.executableURL = URL(fileURLWithPath: "/usr/sbin/nvram")
        task.arguments = ["boot-args=\"amfi_get_out_of_my_way=0x1\""]
        task.standardError = errorPipe

        do {
            try task.run()
        } catch {
            // task launched unsuccessfully
            os_log(.error, log: log, "nvram task launched unsuccessfully: %{public}s", error.localizedDescription)
            reply(error)
            return
        }

        task.waitUntilExit()
        if task.terminationStatus != 0 {
            let errorMsg = readToEOF(pipe: errorPipe)
            os_log(.error, log: log, "nvram task finished unsuccessfully: %{public}s", errorMsg)
            reply(HelperError(.commandError, dueTo: errorMsg))
        } else {
            os_log(.debug, log: log, "Finished setting nvram boot-args")
            reply(nil)
        }
    }
    func overwriteSystemSidecarCore(with src: URL, withReply reply: @escaping (Error?) -> Void) {
        let systemSidecarCoreURL = URL(fileURLWithPath: SYSTEM_SIDECARCORE_PATH)
        os_log(.debug, log: log, "replacing %{public}s with %{public}s", systemSidecarCoreURL.path, src.path)
        do {
            try withRetry(maxRetry: 1) { // for some reason trashItem can throw an error even when the operation is successful
                if FileManager.default.fileExists(atPath: systemSidecarCoreURL.path) {
                    try FileManager.default.trashItem(at: systemSidecarCoreURL, resultingItemURL: nil)
                }
            }
            try FileManager.default.copyItem(at: src, to: systemSidecarCoreURL)
            os_log(.debug, log: log, "successfully replaced system SidecarCore with %{public}s", src.path)
            reply(nil)
        } catch {
            os_log(.error, log: log, "Error when overwriting system SidecarCore: %{public}s %{public}s", String(describing: type(of: error)), error.localizedDescription)
            reply(error)
        }
    }
    func signSystemSidecarCore(withReply reply: @escaping (Error?) -> Void) {
        let task = Process()
        let errorPipe = Pipe()

        task.executableURL = URL(fileURLWithPath: "/usr/bin/codesign")
        task.arguments = ["-f", "-s", "-", SYSTEM_SIDECARCORE_PATH]
        task.standardError = errorPipe

        do {
            try task.run()
        } catch {
            // task launched unsuccessfully
            os_log(.error, log: log, "codesign task launched unsuccessfully: %{public}s", error.localizedDescription)
            reply(error)
            return
        }

        task.waitUntilExit()
        if task.terminationStatus != 0 {
            let errorMsg = readToEOF(pipe: errorPipe)
            os_log(.error, log: log, "codesign task finished unsuccessfully: %{public}s", errorMsg)
            reply(HelperError(.commandError, dueTo: errorMsg))
        } else {
            os_log(.debug, log: log, "Finished code signing")
            reply(nil)
        }
    }
}
