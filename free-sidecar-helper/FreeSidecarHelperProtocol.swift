//
//  FreeSidecarHelperProtocol.swift
//  free-sidecar-helper
//
//  Created by Ben Zhang on 2020-04-14.
//  Copyright © 2020 Ben Zhang. All rights reserved.
//

import Foundation
import ServiceManagement

@objc public class HelperError: NSObject, Error {
    public enum ErrorType {
        case unknownError
        case commandError
    }

    public let type: ErrorType
    public let localizedDescription: String

    public init(_ type: ErrorType, dueTo description: String? = nil) {
        self.type = type
        self.localizedDescription = description ?? "An error of type \(type) occured in the helper"
    }
}

@objc public protocol FreeSidecarHelperProtocol {
    func getBuildNumber(withReply reply: @escaping (String?) -> Void)
    func getEndpoint(withReply reply: @escaping (NSXPCListenerEndpoint) -> Void)
    func mountRootAsRW(withReply reply: @escaping (Error?) -> Void)
    func setNVRAMBootFlag(withReply reply: @escaping (Error?) -> Void)
    func overwriteSystemSidecarCore(with src: URL, withReply reply: @escaping (Error?) -> Void)
    func signSystemSidecarCore(withReply reply: @escaping (Error?) -> Void)
}
