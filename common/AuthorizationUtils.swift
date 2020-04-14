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
    let osStatus: OSStatus
    let description: String?
    
    init(_ osStatus: OSStatus) {
        self.osStatus = osStatus
        self.description = String(describing: SecCopyErrorMessageString(osStatus, nil))
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
    var err: AuthorizationError?

    init(rights: [AuthorizationString], flags: AuthorizationFlags) {
        var authItems = rights.map { AuthorizationItem(name: $0, valueLength: 0, value: nil, flags: 0) }
        let authItemsCount = authItems.count
        authItems.withUnsafeMutableBufferPointer {
            var authRights = AuthorizationRights(count: UInt32(authItemsCount), items: $0.baseAddress)
            
            do {
                try executeAuthorizationFunction { AuthorizationCreate(&authRights, nil, flags, &authRef) }
            } catch let error as AuthorizationError {
                err = error
            } catch {
                os_log(.error, log: log, "An unknown error occured when creating an authorization: %{public}s", error.localizedDescription)
            }
        }
    }
    
    func makeExternalForm() -> AuthorizationExternalForm? {
        guard let ref = authRef else {
            return nil
        }
        
        var extForm = AuthorizationExternalForm()
        do {
            try executeAuthorizationFunction { AuthorizationMakeExternalForm(ref, &extForm) }
            return extForm
        } catch let error as AuthorizationError {
            err = error
        } catch {
            os_log(.error, log: log, "An unknown error occured when creating an authorization: %{public}s", error.localizedDescription)
        }
        
        return nil
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
    let authorization = Authorization(rights: [], flags: [])
    
    return authorization.authRef != nil && authorization.makeExternalForm() != nil
}
