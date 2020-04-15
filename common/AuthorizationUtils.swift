//
//  AuthorizationUtils.swift
//  free-sidecar-xpc
//
//  Created by Ben Zhang on 2020-04-14.
//  Copyright © 2020 Ben Zhang. All rights reserved.
//

import Foundation
import os.log

public struct AuthorizationError: Error {
    let osStatus: OSStatus?
    let description: String?
    
    init(_ osStatus: OSStatus) {
        self.osStatus = osStatus
        self.description = String(describing: SecCopyErrorMessageString(osStatus, nil))
    }

    init(_ description: String) {
        self.osStatus = nil
        self.description = description
    }
}

/**
 @class AuthorizationState
 @abstract Class to manage the creation and destruction of authorization rights
 */
public class Authorization {
    // Opaque pointers are non-nullable: https://stackoverflow.com/a/39979677/4527337
    //   so here we use ? to represent its NULL value
    var authRef: AuthorizationRef?

    init(rights: [AuthorizationString], flags: AuthorizationFlags) throws {
        var authItems = rights.map { AuthorizationItem(name: $0, valueLength: 0, value: nil, flags: 0) }
        let authItemsCount = authItems.count
        try authItems.withUnsafeMutableBufferPointer {
            var authRights = AuthorizationRights(count: UInt32(authItemsCount), items: $0.baseAddress)
            
            try executeAuthorizationFunction { AuthorizationCreate(&authRights, nil, flags, &authRef) }
        }
    }
    
    /**
     @method init
     @abstract Creates an Authorization object without rights, as described in https://developer.apple.com/library/archive/documentation/Security/Conceptual/authorization_concepts/03authtasks/authtasks.html#//apple_ref/doc/uid/TP30000995-CH206-BBCHCEEG
     */
    convenience init() throws {
        try self.init(rights: [], flags: [])
    }

    /**
     @method init
     @abstract Creates an Authorization object from external from, as described in https://developer.apple.com/library/archive/documentation/Security/Conceptual/authorization_concepts/03authtasks/authtasks.html#//apple_ref/doc/uid/TP30000995-CH206-TPXREF14
     */
    convenience init(externalForm: AuthorizationExternalForm) throws {
        try self.init()

        var extForm = externalForm // mutable copy

        try executeAuthorizationFunction { AuthorizationCreateFromExternalForm(&extForm, &authRef) }
    }

    /**
     @method authorizeRights
     @abstract use the AuthorizationCopyRights function to authorize/preauthorize rights
     */
    func authorizeRights(rights: [AuthorizationString], flags: AuthorizationFlags) throws {
        guard let ref = authRef else {
            throw AuthorizationError("authRef is nil")
        }
        
        var authItems = rights.map { AuthorizationItem(name: $0, valueLength: 0, value: nil, flags: 0) }
        let authItemsCount = authItems.count
        try authItems.withUnsafeMutableBufferPointer {
            var authRights = AuthorizationRights(count: UInt32(authItemsCount), items: $0.baseAddress)

            try executeAuthorizationFunction { AuthorizationCopyRights(ref, &authRights, nil, flags, nil) }
        }
    }

    func makeExternalForm() throws -> AuthorizationExternalForm {
        guard let ref = authRef else {
            throw AuthorizationError("authRef is nil")
        }
        
        var extForm = AuthorizationExternalForm()
        try executeAuthorizationFunction { AuthorizationMakeExternalForm(ref, &extForm) }
        return extForm
    }
    
    deinit {
        if let ref = authRef { // authRef is secretly an OpaquePointer
            authRef = nil
            AuthorizationFree(ref, .destroyRights)
        }
    }
}

/**
 @function executeAuthorizationFunction
 @abstract Wrapper around Authorization Service functions to make them more Swift-y
 @result A reference to an error string, or NULL if no error string is available for the specified result code. Your code must release this reference by calling the CFRelease function.
 */
private func executeAuthorizationFunction(_ authorizationFunction: () -> (OSStatus) ) throws {
    let osStatus = authorizationFunction()
    guard osStatus == errAuthorizationSuccess else {
        throw AuthorizationError(osStatus)
    }
}

/**
 @function isAuthorizationAvailable
 @abstract checks if the Authorization is accessible by creating an empty authorization
 */
public func isAuthorizationAvailable() -> Bool {
    let authorization = try? Authorization(rights: [], flags: [])
    
    return authorization?.authRef != nil && (try? authorization?.makeExternalForm()) != nil
}
