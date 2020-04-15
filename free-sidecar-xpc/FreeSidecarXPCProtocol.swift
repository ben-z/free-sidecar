//
//  FreeSidecarXPCProtocol.swift
//  free-sidecar-xpc
//
//  Created by Ben Zhang on 2020-04-13.
//  Copyright © 2020 Ben Zhang. All rights reserved.
//

import Foundation
import ServiceManagement

@objc public class XPCServiceError: NSObject, Error {
    public enum ErrorType {
        case unknownError
        case authUnavailable
    }
    
    public let type: ErrorType
    
    public init(_ type: ErrorType) {
        self.type = type
    }
}

@objc public protocol FreeSidecarXPCProtocol {
    func upperCaseString(_ string: String, withReply reply: @escaping (String) -> Void)
    func upperCaseAndJoinStrings(_ string1: String, _ string2: String, withReply reply: @escaping (String) -> Void)
    func installHelper(withReply reply: @escaping (Error?) -> Void)
}
