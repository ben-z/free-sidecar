//
//  main.m
//  free-sidecar-xpc
//
//  Created by Ben Zhang on 2020-04-13.
//  Copyright © 2020 Ben Zhang. All rights reserved.
//
//  The Swift XPC service starter code is taken from
//    https://matthewminer.com/2018/08/25/creating-an-xpc-service-in-swift.html

import Foundation

let delegate = FreeSidecarXPCDelegate()
let listener = NSXPCListener.service()
listener.delegate = delegate
listener.resume()
