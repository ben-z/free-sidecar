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
    }

    public let type: ErrorType

    public init(_ type: ErrorType) {
        self.type = type
    }
}

@objc public protocol FreeSidecarHelperProtocol {
    func lowerCaseString(_ string: String, withReply reply: @escaping (String) -> Void)
    func getBuildNumber(withReply reply: @escaping (String?) -> Void)
}
